// *************************************************************************
//   システム	： CryptoEA
//   概要		： EA用の実行ファイル
//   注意		： なし
//   メモ		： なし
// **************************    履    歴    *******************************
// 		v1.0		2021.04.14			Taji		新規
// 		v1.1		2021.08.02			Taka		インプットの設定を追加
// *************************************************************************/

//**************************************************
// インクルードファイル（include）
//**************************************************
#include "Logger.mqh"
#include "OrderManager.mqh"
#include "DisplayInfo.mqh"
#include "CheckerException.mqh"
#include "Configuration.mqh"
#include "CheckerBars.mqh"

//**************************************************
// UIインプット
//**************************************************
// 既存
input int trailingStop_mode = 100;
input double input_SetSLFromTP_range = -1;
input double input_trailingStop_range = -1;
input double input_terminalg_lot = -1;
// 新規
input double AM_1stLot				= 0.01;		// 初期ロット [lot]
input int AM_Averaging_1st_width	= 400;		// 1-2ピン目の幅 [USD]
input int AM_MarginRateLimiter		= 5000;		// 証拠金維持率リミッター [%]


class CHandler
{
	private:
		static CHandler*    m_handler;
		CLogger*            C_logger;
		COrderManager*      C_OrderManager;
		CDisplayInfo*       C_DisplayInfo;
		CCheckerException*  C_CheckerException;
		CCheckerBars*       C_CheckerBars;
		bool				b_fin1stOninit;			// Oninit関数が初回実行の完了(false:未実行、true:実行)
	
		//プライベートコンストラクタ(他のクラスにNewはさせないぞ！！！)
		CHandler(){
			C_logger = CLogger::GetLog();
			C_OrderManager = COrderManager::GetOrderManager();
			C_DisplayInfo = CDisplayInfo::GetDisplayInfo();
			C_CheckerException = CCheckerException::GetCheckerException();
			C_CheckerBars = CCheckerBars::GetCheckerBars();
			b_fin1stOninit = false;
		}

		//配列番号へ変換
		char ArreyNumFromOderType(ENUM_ORDER_TYPE type){
			if(type==ORDER_TYPE_BUY) return 0;
			if(type==ORDER_TYPE_SELL) return 1;
			C_logger.output_log_to_file("Handler::ArreyNumFromOderType[ERROR] pre order type");
			return 0;
		}
		char ArreyNumFromPositionType(ENUM_POSITION_TYPE type){
			if(type==POSITION_TYPE_BUY) return 0;
			if(type==POSITION_TYPE_SELL) return 1;
			C_logger.output_log_to_file("Handler::ArreyNumFromPositionType[ERROR] pre position type");
			return 0;
		}

	public:
		//	機能		： //シングルトンクラスインスタンス取得
		static CHandler* GetHandler()
		{
			if(CheckPointer(m_handler) == POINTER_INVALID){
				m_handler = new CHandler();
			}
			return m_handler;
		}

		// *************************************************************************
		//	機能		： 期限切れ判断関数
		//	注意		： なし
		//	メモ		： タイマー関数内でコール
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// *************************************************************************/
		void Chk_Expired() {
			// 有効期限切れ
			if( C_CheckerException.Chk_Expired() == false ){
				//C_logger.output_log_to_file("フェードアウトモード移行");
				GlobalVariableSet("terminalg_fadeout_mode",true);
			}	
		}
		
		
		// *************************************************************************
		//	機能		： 指定タイプの最後に注文された価格を取得する
		//	注意		： なし
		//	メモ		： なし
		//	引数		： 注文の種類（売り/買いなど）
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// *************************************************************************/
		double get_latestOrderOpenPrice( ENUM_POSITION_TYPE req_type ){
			
			return C_OrderManager.LatestOrderOpenPrice( req_type );
		}
		
		
		// *************************************************************************
		//	機能		： グローバル変数を初期化
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.03			taka		新規
		// *************************************************************************/
		void initGlobalVal( void ){
			
            //グローバル変数の掃除
			if( true == GlobalVariableCheck("tg_StopOrderJudge_range") ){
				GlobalVariableDel("tg_StopOrderJudge_range");
			}
			if( true == GlobalVariableCheck("tg_StopOrderJudge_minutes") ){
				GlobalVariableDel("tg_StopOrderJudge_minutes");
			}

			//ロット最小値のターミナルグローバル変数がなければ初期化
			if( false == GlobalVariableCheck("terminalg_lot")){
				GlobalVariableSet("terminalg_lot",BASE_LOT);
			}
			if( input_terminalg_lot >= 0 ){
				GlobalVariableSet("terminalg_lot",input_terminalg_lot);
			}

			//フェードアウトモードのターミナルグローバル変数がない場合は初期化
			if( false == GlobalVariableCheck("terminalg_fadeout_mode")){
				GlobalVariableSet("terminalg_fadeout_mode",false);
			}

			//トレーリングストップモードのターミナルグローバル変数がなければ初期化
			if( false == GlobalVariableCheck("tg_trailingStop_mode")){
				GlobalVariableSet("tg_trailingStop_mode",false);
			}
			if( trailingStop_mode == 1) {
				GlobalVariableSet("tg_trailingStop_mode",true);
			}
			if( trailingStop_mode == 0) {
				GlobalVariableSet("tg_trailingStop_mode",false);
			}

			//トレーリングストップ幅のターミナルグローバル変数がなければ初期化
			if( false == GlobalVariableCheck("tg_trailingStop_range")){
				GlobalVariableSet("tg_trailingStop_range",100);
			}
			if( input_trailingStop_range >= 0 ){
				GlobalVariableSet("tg_trailingStop_range",input_trailingStop_range);
			}

			//TPを一定幅超えた場合にSLをTP値に設定する。TPの超え幅の値。
			if( false == GlobalVariableCheck("tg_SetSLFromTP_range")){
				GlobalVariableSet("tg_SetSLFromTP_range",5);
			}
			if( input_SetSLFromTP_range >= 0 ){
				GlobalVariableSet("tg_SetSLFromTP_range",input_SetSLFromTP_range);
			}

			//BUY注文停止上限値のターミナルグローバル変数がなければ初期化
			if( false == GlobalVariableCheck("tg_BuyOrderStopLimitMaxPrice")){
				GlobalVariableSet("tg_BuyOrderStopLimitMaxPrice",1000000);
			}

			//SELL注文停止下限値のターミナルグローバル変数がなければ初期化
			if( false == GlobalVariableCheck("tg_SellOrderStopLimitMinPrice")){
				GlobalVariableSet("tg_SellOrderStopLimitMinPrice",0);
			}
		}
		
		
		// *************************************************************************
		//	機能		： 初期化処理
		//	注意		： なし
		//	メモ		： なし
		//	引数		： ノーポジの場合は最小ロット建てる、ポジションある場合は前回ポジション値更新、TPも更新
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// 		v1.1		2021.08.04			Taka		2回目起動以降は何もしないようにする
		// *************************************************************************/
		void OnInit(){
			
			static bool b_first = false;		// 初回判定フラグ(false:初回、true:2回目～)
			
			// 起動ログ
			C_logger.output_log_to_file( 
				StringFormat("Handler::OnInit 初期化の処理開始 [初回]%d (0:初回、1:2回目～)", (int)b_first ) 
			);
			
			/* これ以降は初回立ち上がり時のみ実行とする */
			if( b_first == true ){
				
				return;		// 2回目以降は何もしない
			} 
			
			// グローバル変数の初期化
			initGlobalVal();
			
			// 口座番号確認
			if( C_CheckerException.Chk_Account() == false ){
				C_logger.output_log_to_file("Handler::OnInit 起動対象ではない -> EA終了");
				if( SPECIFIED_ACCOUNT_CHECK == true ){
					ExpertRemove();					// OnDeinit()をコールしてEA終了処理
				}
			}
			
			// カスタムテーブル処理(Configuration.mqh)
			ConfigCustomizeLotList();
			ConfigCustomizeDiffPriceOrderList();
			ConfigCustomizeTPTable();
			
			// 単体テスト（各test項目をif(0)で制御）
			if(0){
				C_OrderManager.unit_test();
			}
			
			// TPスキャン
//			C_OrderManager.UpdateSLTP( POSITION_TYPE_BUY );
//			C_OrderManager.UpdateSLTP( POSITION_TYPE_SELL );
			
			// 1回しか実行させないようにする
			b_first = true;
			b_fin1stOninit = true;		// Oninit関数が初回実行の完了(false:未実行、true:実行)
			
			C_logger.output_log_to_file("Handler::OnInit 初期化の処理終了");		// ログ
		}
		
		
		// *************************************************************************
		//	機能		： Timer関数
		//	注意		： なし
		//	メモ		： 
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// *************************************************************************/
		void OnTimer(){
			
		}
		
		
		// *************************************************************************
		//	機能		： OnTickの取引処理
		//	注意		： なし
		//	メモ		： ロット数や注文幅はこの関数で処理
		//	引数		： 注文の種類（売り/買いなど）
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.04			Taka		新規
		// *************************************************************************/
		void OnTickPosition( ENUM_POSITION_TYPE en_pos ){
			
//			double	base_lot = GlobalVariableGet("terminalg_lot");		// 初期ロット取得
			double	base_lot = AM_1stLot;								// 初期ロット取得
			double	nowPrice;											// 現在価格
			double	lastPrice;											// 最終価格
			double	diff;												// 現在価格と最後の注文との差額を計算
			double	diffNextPrice;										// 次の値段までの差分
			int 	TotalOrderNum;										// 全注文数
			ENUM_ORDER_TYPE	en_order;									// 注文方法
			double	lot = 0.0;											// 注文量
			
			/* 注文数取得 */
			TotalOrderNum = C_OrderManager.get_TotalOrderNum( en_pos );

			/* 注文処理 */
			if( TotalOrderNum == 0 ){		// 新規注文
				
				/* 取引に応じた注文（BUY or SELL） */
				if( en_pos == POSITION_TYPE_BUY ){
					
					C_logger.output_log_to_file("Handler::OrderNoPosition  Buyの1ピン目");
					C_OrderManager.OrderTradeActionDeal( base_lot, ORDER_TYPE_BUY);		// 新規注文
				}
				else if( en_pos == POSITION_TYPE_SELL ){
					
					C_logger.output_log_to_file("Handler::OrderNoPosition  Sellの1ピン目");
					C_OrderManager.OrderTradeActionDeal( base_lot, ORDER_TYPE_SELL);	// 新規注文
				}
				C_logger.output_log_to_file( 
					StringFormat("[差分1]%d, [type]%d (0:buy 1:sell)", diff_price_order[0], (int)en_pos ) 
				);
			}
			else{							// 2ピン目～注文
				
				/* 差分確認 */
				lastPrice = get_latestOrderOpenPrice(en_pos);				// 最終価格
				diffNextPrice = diff_price_order[TotalOrderNum - 1];		// 次の価格との差
				// 現在価格
				if( en_pos == POSITION_TYPE_BUY ){		// 買い取引
					
					nowPrice	= SymbolInfoDouble( Symbol(), SYMBOL_ASK );	// BUYの現在価格
					diff 		= lastPrice - nowPrice;						// 現在価格との差
					en_order	= ORDER_TYPE_BUY;							// BUYの注文
				}
				else{									// 売り取引
					nowPrice	= SymbolInfoDouble( Symbol(), SYMBOL_BID );	// SELLの現在価格
					diff 		= nowPrice - lastPrice;						// 現在価格との差
					en_order	= ORDER_TYPE_SELL;							// SELLの注文
				}
				
#ifdef debug_Handler
				C_logger.output_log_to_file( StringFormat("[売買]%d(0:buy 1:sell) [現在との価格差]%d [次の価格差]%d", (int)en_pos, (int)diff, (int)diffNextPrice ) );
				C_logger.output_log_to_file( StringFormat("[現在価格]%d [最終価格]%d", (int)nowPrice, (int)lastPrice ) );
#endif
				/* 所定のピン幅下がったら追加注文 */
				if( diff > diffNextPrice ){
					
					lot = base_lot * MathPow( 1.278, TotalOrderNum );	// 注文量 
					C_OrderManager.OrderTradeActionDeal( lot, en_order );	// 追加注文
					C_logger.output_log_to_file( StringFormat("注文実施 [売買]%d(0:buy 1:sell) [lot]%f", lot ) );
				}
			}
			C_logger.output_log_to_file( StringFormat("全注文数　=　%d", TotalOrderNum ) );		// BUY数
		}
		
		
		// *************************************************************************
		//	機能		： OnTickの価格更新処理
		//	注意		： なし
		//	メモ		： なし
		//	引数		： 注文の種類（売り/買いなど）
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.04			Taka		新規
		// *************************************************************************/
		void OnTickUpdatePrice( ENUM_POSITION_TYPE en_pos ){
			
			double newTP;
			
			C_OrderManager.UpdateOrderList();				// EA注文リストデータを更新する
			newTP = C_OrderManager.GetNewTP( en_pos );		// TP取得
			C_OrderManager.SetTP( en_pos, newTP );			// TP設定
		}
			
			
		// *************************************************************************
		//	機能		： 価格更新ごとに実行される関数
		//	注意		： なし
		//	メモ		： 
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// 		v1.1		2021.08.04			Taka		自動売買のチェック許可がない場合の処理を追加
		// *************************************************************************/
		void OnTick(){
			
			if( b_fin1stOninit == false ) return;	// Onintが完了するまで処理をスタートしない 
			
			//C_DisplayInfo.UpdateOrderInfo();		// 注文情報を更新
			
			/* チャート上にコメントを表示 */
			C_DisplayInfo.ShowData( C_CheckerException.Get_chkAccountState() );
			
			/* 日付チェック（有効期限外ならばフェードアウトモード移行） */
			Chk_Expired();
			
			/* 自動売買許可されていないかチェック */
//#ifdef AAA
			if( TerminalInfoInteger( TERMINAL_TRADE_ALLOWED ) == false ){		// 「アルゴリズム取引ボタン」OFFなら実行しない
				
				C_logger.output_log_to_file("OnTick: アルゴリズム取引ボタンOFF");
				return;
			}
			if( MQLInfoInteger( MQL_TRADE_ALLOWED ) == false ){	// 自動売買の許可のチェックが入っていない
			
				C_logger.output_log_to_file("OnTick: 自動売買許可のチェックなし");
				return;
			}
//#endif
			/* 証拠金維持率確認 */
			// 維持率が低ければ、取引増やさない
			
			/* 急激な値動き確認 */
			// 急騰急落の場合には注文を行わない

			/* 取引処理（注文関連） */
			OnTickPosition( POSITION_TYPE_BUY );		// Buyの取引
			OnTickPosition( POSITION_TYPE_SELL );		// Sellの取引

			/* 価格更新処理 */
			OnTickUpdatePrice( POSITION_TYPE_BUY );		// Buyの価格更新
			OnTickUpdatePrice( POSITION_TYPE_SELL );	// Sellの価格更新



#ifdef AAA		
	
			// 証拠金維持率チェック (所定のパーセンテージ下回ったら取引しない)
			if( AccountInfoDouble( ACCOUNT_MARGIN_LEVEL ) != 0 ){			// ポジションが0の時は維持率0になる
				if( AccountInfoDouble( ACCOUNT_MARGIN_LEVEL ) < MINIMUN_ACCOUNT_MARGIN_LEVEL ){
					//C_logger.output_log_to_file(StringFormat("証拠金維持率　=　%f",AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)));
					return;
				}
			}
			
			// 急激な値幅の有無チェック。急な上場時はSELLを入れない。急な下降時はBUYを入れない
			int deal_recomment;
			int diff_price_for_order = BASE_DIFF_PRICE_TO_ORDER2;
//			deal_recomment = C_CheckerBars.Chk_preiod_m1_bars();
			//deal_recomment_for_super = C_CheckerBars.Chk_preiod_m1_bars_stoporder();//壮大な過剰変動時対応

			//#######################################ロングの処理start##################################################
			if( RECOMMEND_STOP_BUY_DEAL != deal_recomment  ){ //BUYが値幅チェックにより制限がかかっていなければ処理開始
				
				//注文処理
				int TotalOrderNumBuy = C_OrderManager.get_TotalOrderNum(POSITION_TYPE_BUY);
				if(0 != TotalOrderNumBuy){
					//ロングの前回ポジからの現在価格との差を計算
					double ask_diff = get_latestOrderOpenPrice(POSITION_TYPE_BUY) - SymbolInfoDouble(Symbol(),SYMBOL_ASK);
					diff_price_for_order = diff_price_order[TotalOrderNumBuy-1];

					//所定のピン幅下がったら、追加量テーブルに従って所定量追加
					if(ask_diff > diff_price_for_order){
						//ポジション限界値を超えない場合
						if( C_OrderManager.get_TotalOrderNum(POSITION_TYPE_BUY) < MAX_ORDER_NUM ){
							int num = CalculatePositionNum( POSITION_TYPE_BUY );
							C_logger.output_log_to_file(StringFormat("Handler::OnTick　注文判断変化量=%d 直前ポジと現在価格の差(ASK)=%f lot=%f num=%d",
																	diff_price_for_order, ask_diff, lot_list[num] * base_lot, num));
							C_OrderManager.OrderTradeActionDeal( lot_list[num] * base_lot * 1.278, ORDER_TYPE_BUY);
							//TP更新
							C_OrderManager.UpdateSLTP( POSITION_TYPE_BUY );
						}
					}
				}
				else{
					//ノーポジ時( フェードアウトモード時は注文しない,それ以外は新規注文を行う)
					if( GlobalVariableGet("terminalg_fadeout_mode") == false ){
						OrderForNoPosition();
					}
				}
			}
			//#######################################ロングの処理end######################################################
			//#######################################ショートの処理start##################################################
			if( RECOMMEND_STOP_SELL_DEAL != deal_recomment ){ //SELLが値幅チェックにより制限がかかっていなければ処理開始

				//注文処理
				int TotalOrderNumSell = C_OrderManager.get_TotalOrderNum(POSITION_TYPE_SELL);
				if(0 != TotalOrderNumSell){
					//ショートの前回ポジと現在価格との差を計算
					double bid_diff = SymbolInfoDouble(Symbol(),SYMBOL_BID) - get_latestOrderOpenPrice(POSITION_TYPE_SELL);
					diff_price_for_order = diff_price_order[TotalOrderNumSell-1];

					//所定のピン幅上がったら、追加量テーブルに従って所定量追加
					if(bid_diff > diff_price_for_order){
						//ポジション限界値を超えない場合
						if( C_OrderManager.get_TotalOrderNum(POSITION_TYPE_SELL) < MAX_ORDER_NUM ){
							int num = CalculatePositionNum( POSITION_TYPE_SELL );
							C_logger.output_log_to_file(StringFormat("Handler::OnTick　注文判断変化量=%d 直前ポジと現在価格の差(BID)=%f lot=%f num=%d",
																	diff_price_for_order, bid_diff, lot_list[num] * base_lot, num));
							C_OrderManager.OrderTradeActionDeal( lot_list[num] * base_lot * 1.278, ORDER_TYPE_SELL);
							//TP更新
							C_OrderManager.UpdateSLTP( POSITION_TYPE_SELL );
						} 
					}
				}
				else{
					//ノーポジ時( フェードアウトモード時は注文しない,それ以外は新規注文を行う)
					if( GlobalVariableGet("terminalg_fadeout_mode") == false ){
						OrderForNoPosition();
					}
				}
			}
			//#######################################ショートの処理end######################################################
#endif
		}
		// *************************************************************************
		//	機能		： Trunsaction更新ごとに実行される関数
		//	注意		： なし
		//	メモ		： 
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// *************************************************************************/
		void OnTradeTransaction(
			const MqlTradeTransaction&    trans,        // 取引トランザクション構造体
			const MqlTradeRequest&      request,      //リクエスト構造体
			const MqlTradeResult&       result       // 結果構造体
		){
			ulong deal = trans.deal;    //約定チケット
			ulong order = trans.deal;   //注文チケット
			//ENUM_DEAL_REASON reason = HistoryDealGetInteger(deal,DEAL_REASON);
			ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(order,DEAL_REASON);
			//C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction deal %d",deal));
			//C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction deal_type %d DEAL_TYPE_BUY=%d, DEAL_TYPE_SELL=%d",trans.deal_type,DEAL_TYPE_BUY,DEAL_TYPE_SELL));
			//C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction price_sl %d",trans.price_sl));
			//C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction type %d TRADE_TRANSACTION_DEAL_ADD=%d,TRADE_TRANSACTION_DEAL_UPDATE=%d,TRADE_TRANSACTION_HISTORY_ADD=%d,TRADE_TRANSACTION_HISTORY_UPDATE=%d",trans.type, TRADE_TRANSACTION_DEAL_ADD,TRADE_TRANSACTION_DEAL_UPDATE,TRADE_TRANSACTION_HISTORY_ADD,TRADE_TRANSACTION_HISTORY_UPDATE));
			//C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction reason=  %d DEAL_REASON=%d",reason,DEAL_REASON));
			if( reason == DEAL_REASON_SL ){
				C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction DEAL_REASON_SL %d",trans.deal_type));
				if(trans.deal_type == DEAL_TYPE_BUY){  //約定種類買い
					C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction DEAL_TYPE_BUY trans.type == TRADE_TRANSACTION_DEAL_ADD %d",trans.deal_type));
					//OrderTradeActionCloseAll(POSITION_TYPE_SELL);
				}
				if(trans.deal_type == DEAL_TYPE_SELL){  //約定種類買い
					C_logger.output_log_to_file(StringFormat("Handler::OnTradeTransaction DEAL_TYPE_SELL trans.type == TRADE_TRANSACTION_DEAL_ADD %d",trans.deal_type));
					//OrderTradeActionCloseAll(POSITION_TYPE_BUY);
				}
			}
		}

		// *************************************************************************
		//	機能		： 終了関数
		//	注意		： なし
		//	メモ		： 
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// *************************************************************************/
		void OnDeinit(const int reason){
			Print("Handler::OnDeinit()");
		}
};
CHandler* CHandler::m_handler;