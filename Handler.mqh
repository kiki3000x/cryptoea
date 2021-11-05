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
// 定義（define）
//**************************************************

//**************************************************
// 列挙体（enum）
//**************************************************

//**************************************************
// 構造体（struct）
//**************************************************

//**************************************************
// グローバル変数
//**************************************************

//**************************************************
// UIインプット
//**************************************************
// 新規
input bool AM_FadeoutModeBuy		= false;			// <AM> *Buyフェードアウト機能 : 0:OFF,1:ON
input bool AM_FadeoutModeSell		= false;			// <AM> *Sellフェードアウト機能 : 0:OFF,1:ON
input double AM_1stLotBuy			= 0.01;				// <AM> Buy初期ロット [lot] : 0.01-
input double AM_1stLotSell			= 0.01;				// <AM> Sell初期ロット [lot] : 0.01-
input double AM_orderLotGain		= ORDER_LOT_GAIN;	// <AM> ロット増加比率 [倍] : 1.2-1.3
input int AM_1st_buy_width			= 100;				// <AM> BUY 1-2ピン目の幅 [USD] : 100-
input int AM_1st_sell_width			= 100;				// <AM> SELL 1-2ピン目の幅 [USD] : 100-
input int AM_MarginRateLimiter		= 3000;				// <AM> 証拠金維持率リミッタ [%] : 1000-
input int AM_OneSideMaxOrderNum		= MAX_ORDER_NUM;	// <AM> 片側のEA注文最大数 [注文] : 0-12
input bool ES_BigDivMode			= true;				// <ES> 急騰急落注文抑止機能 : 0:OFF,1:ON
input int ES_PriceDiv1min			= 200;				// <ES> 1分足の急激変化価格 [USD] : 50-
input int ES_PriceDiv5min			= 250;				// <ES> 5分足の急激変化価格 [USD] : 50-
input int ES_PriceDivnmin_num		= 20;				// <ES> n分足の急激変化 [分] : 6-60
input int ES_PriceDivnmin			= 350;				// <ES> n分足の急激変化価格 [USD] : 50-
input int EL_MaxEntryPrice			= 80000;			// <EL> *最大新規注文価格 [USD] : 20000-
input int EL_MinEntryPrice			= 20000;			// <EL> *最低新規注文価格 [USD] : 20000-
input bool AB_BothEntry				= false;			// <AB> アタッカ&バランサ機能 : 0:OFF,1:ON
input double AB_MaxBackRatio		= 30.0;				// <AB> 最大利益の折返し比率 [%] : 10-50
input int AB_StaBlncrNum			= 2;				// <AB> バランサ開始の注文数 [注文目] : 2-4



//**************************************************
// CHandlerクラス
//**************************************************
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
			
			/* 起動ログ */
			C_logger.output_log_to_file( 
				StringFormat("Handler::OnInit 初期化の処理開始 [初回]%d (0:初回、1:2回目～)", (int)b_first ) 
			);
			
			/* これ以降は初回立ち上がり時のみ実行とする */
			if( b_first == true ){
				
				return;		// 2回目以降は何もしない
			} 
			
			/* 口座番号確認 */
			if( C_CheckerException.Chk_Account() == false ){
				C_logger.output_log_to_file("Handler::OnInit 起動対象ではない -> EA終了");
				if( SPECIFIED_ACCOUNT_CHECK == true ){
					ExpertRemove();					// OnDeinit()をコールしてEA終了処理
				}
			}
			
			/* 設定値の変更処理(Configuration.mqh) */
			ConfigCustomizeDiffPriceOrderList();
			
			// 単体テスト（各test項目をif(0)で制御）
			if(0){
				C_OrderManager.unit_test();
			}
			
			/* 1回しか実行させないようにする */
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
		// 		v1.1		2021.08.06			Taka		急騰急落注文抑止 機能 追加（2ピン目から稼働）
		// *************************************************************************/
		void OnTickPosition( ENUM_POSITION_TYPE en_pos ){
			
			double	base_lot;					// 初期ロット取得
			double	nowPrice;					// 現在価格
			double	lastPrice;					// 最終価格
			double	diff;						// 現在価格と最後の注文との差額を計算
			double	diffNextPrice;				// 次の値段までの差分
			double	avePrice;					// 平均価格
			int 	TotalOrderNum;				// 全注文数
			ENUM_ORDER_TYPE	en_order;			// 注文方法
			double	lot = 0.0;					// 注文量
			
			/* 注文数取得 */
			TotalOrderNum = C_OrderManager.get_TotalOrderNum( en_pos );
			
			/* 片側の注文数が最大値に到達していたら何もしない */
			if( TotalOrderNum >= AM_OneSideMaxOrderNum ){
				return;
			}
			
			/* 注文処理 */
			if( TotalOrderNum == 0 ){		// 新規注文
				
				/* 価格の最大値、最小限を超えていない範囲で注文を実施 */
				avePrice = ( SymbolInfoDouble(Symbol(), SYMBOL_ASK ) + SymbolInfoDouble(Symbol(), SYMBOL_ASK ) ) * 0.5;
				if( ( avePrice < EL_MinEntryPrice ) || ( EL_MaxEntryPrice < avePrice ) ){
					return;
				}
				
				/* 取引に応じた注文（BUY or SELL） */
				if( en_pos == POSITION_TYPE_BUY ){
				
					/* フェードアウト機能が有効なら新規注文は入れない（新規注文だけチェックすればOK） */
					if( AM_FadeoutModeBuy == true ){
						return;
					}
					
					C_logger.output_log_to_file("Handler::OrderNoPosition  Buyの1ピン目");
					C_OrderManager.OrderTradeActionDeal( AM_1stLotBuy, ORDER_TYPE_BUY);		// 新規注文
				}
				else if( en_pos == POSITION_TYPE_SELL ){
					
					/* フェードアウト機能が有効なら新規注文は入れない（新規注文だけチェックすればOK） */
					if( AM_FadeoutModeSell == true ){
						return;
					}
					
					C_logger.output_log_to_file("Handler::OrderNoPosition  Sellの1ピン目");
					C_OrderManager.OrderTradeActionDeal( AM_1stLotSell, ORDER_TYPE_SELL);	// 新規注文
				}
				C_logger.output_log_to_file( 
					StringFormat("[差分1buy]%d,[差分1sell]%d, [type]%d (0:buy 1:sell)", diff_buy_price_order[0], diff_sell_price_order[0], (int)en_pos ) 
				);
			}
			else{							// 2ピン目～注文
				
				/* 急激な値動き確認 */
				if( true == C_CheckerBars.Is_warningPriceDiv() ){		// 急激な価格変化を検知したため、注文を入れない
					return;
				}
				
				/* 証拠金維持率確認 */
				// 維持率が低ければ、取引増やさない
				if( AccountInfoDouble( ACCOUNT_MARGIN_LEVEL ) != 0 ){			// ポジションが0の時は維持率0になる
				
					if( AccountInfoDouble( ACCOUNT_MARGIN_LEVEL ) < AM_MarginRateLimiter ){		// 所定より低ければ注文入れない
						return;
					}
				}
				
				/* 差分確認 */
				lastPrice = get_latestOrderOpenPrice(en_pos);				// 最終価格
				// 現在価格
				if( en_pos == POSITION_TYPE_BUY ){		// 買い取引
					
					diffNextPrice = diff_buy_price_order[TotalOrderNum - 1];		// 次の価格との差
					nowPrice	= SymbolInfoDouble( Symbol(), SYMBOL_ASK );	// BUYの現在価格
					diff 		= lastPrice - nowPrice;						// 現在価格との差
					en_order	= ORDER_TYPE_BUY;							// BUYの注文
					base_lot	= AM_1stLotBuy;								// Buyの注文量
				}
				else{									// 売り取引
					
					diffNextPrice = diff_sell_price_order[TotalOrderNum - 1];		// 次の価格との差
					nowPrice	= SymbolInfoDouble( Symbol(), SYMBOL_BID );	// SELLの現在価格
					diff 		= nowPrice - lastPrice;						// 現在価格との差
					en_order	= ORDER_TYPE_SELL;							// SELLの注文
					base_lot	= AM_1stLotSell;							// SELLの注文量
				}
				
#ifdef debug_Handler
				C_logger.output_log_to_file( StringFormat("[売買]%d(0:buy 1:sell) [現在との価格差]%d [次の価格差]%d", (int)en_pos, (int)diff, (int)diffNextPrice ) );
				C_logger.output_log_to_file( StringFormat("[現在価格]%d [最終価格]%d", (int)nowPrice, (int)lastPrice ) );
#endif
				/* 所定のピン幅下がったら追加注文 */
				if( diff > diffNextPrice ){
					
					lot = base_lot * MathPow( AM_orderLotGain, TotalOrderNum );	// 注文量 
					C_OrderManager.OrderTradeActionDeal( lot, en_order );		// 追加注文
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
		//	機能		： OnTickの通常ナンピン処理
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.04			Taka		新規
		// *************************************************************************/
		void OnTickAM( void ){
			
			C_logger.output_log_to_file("■■■ OnTick: 動作 -> 通常モード");
			
			/* 取引処理（注文関連） */
			OnTickPosition( POSITION_TYPE_BUY );		// Buyの取引
			OnTickPosition( POSITION_TYPE_SELL );		// Sellの取引
			
			/* 価格更新処理 */
			OnTickUpdatePrice( POSITION_TYPE_BUY );		// Buyの価格更新
			OnTickUpdatePrice( POSITION_TYPE_SELL );	// Sellの価格更新
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
			
			/* ナンピンの注文方法に応じて注文を実施 */
			if( AB_BothEntry == false ){		// 通常モード
				OnTickAM();
			}
			else{		// アタッカー&バランサーモード
//				OnTickBL();
			}
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