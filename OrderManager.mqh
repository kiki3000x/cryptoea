//**************************************************
// class COrderManager
//**************************************************

//**************************************************
// インクルードファイル（include）
//**************************************************
#include "Logger.mqh"
#include "Configuration.mqh"


//**************************************************
// 定義（define）
//**************************************************

//**************************************************
// 列挙体（enum）
//**************************************************

//**************************************************
// 構造体（struct）
//**************************************************
/* EA注文リストデータ */
struct stORDER
{
	int		i_orderNum;					// 注文数
	double	d_price[MAX_EA_NUM];		// 各価格
	double	d_volume[MAX_EA_NUM];		// 各ロット
	double	d_swap[MAX_EA_NUM];			// 各スワップ
	double	d_tp[MAX_EA_NUM];			// 各TP
	double	d_SL[MAX_EA_NUM];			// 各SL
	int		i_digits[MAX_EA_NUM];		// 各小数点以下の桁数
	long	l_createTime[MAX_EA_NUM];	// 各注文が出された時刻
	string	s_comment;					// コメント
};


//**************************************************
// グローバル変数
//**************************************************
// EA管理下のポジションリスト
static stORDER st_BuyEA;			// EA管理下のBUYリスト
static stORDER st_SellEA;			// EA管理下のSELLリスト


//**************************************************
// クラス
//**************************************************
class COrderManager
{

	private:
		static COrderManager* m_OrderManager;
		CLogger*              C_logger;

		
		COrderManager(){
			C_logger = CLogger::GetLog();
		}

	public:

		static COrderManager* GetOrderManager(){
			if(CheckPointer(m_OrderManager) == POINTER_INVALID){
				m_OrderManager = new COrderManager();
			}
			
			/* オブジェクト生成時にデータ初期化 */
			ZeroMemory( st_BuyEA );
			ZeroMemory( st_SellEA );
			
			return m_OrderManager;
		}
		
		
		// *************************************************************************
		//	機能		： EA注文リストデータを初期化する
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.05			Taka		新規
		// *************************************************************************/
		void ClrOrderList( void ){
			
			/* オブジェクト生成時にデータ初期化 */
			ZeroMemory( st_BuyEA );
			ZeroMemory( st_SellEA );
			
			/* Debug */
//			Print(StringFormat("st_BuyEA:  d_price[0]%f [1]%f [2]%f [3]%f [4]%f",
//								st_BuyEA.d_price[0], st_BuyEA.d_price[1], st_BuyEA.d_price[2], st_BuyEA.d_price[3], st_BuyEA.d_price[4] )
//			);
//			Print( StringFormat("st_BuyEA:  [comment]%s", st_BuyEA.s_comment ) );
		}
		
		
		// *************************************************************************
		//	機能		： EA注文リストデータを更新する
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.05			Taka		新規
		// *************************************************************************/
		void UpdateOrderList( void ){
			
			int		total = PositionsTotal();	// 注文の種類に応じた全ポジション数（EAと手打ち）
			ulong	ticket;						// ポジションチケット取得（コールする儀式）
			string	symbol;						// シンボル
			ulong	magic;						// マジックナンバー
			ENUM_POSITION_TYPE type;			// 売買タイプ
			int		index_buy = 0;				// 保有ポジション数(買い)
			int		index_sell = 0;				// 保有ポジション数(売り)
#ifdef debug_Handler
			static int i_sec = 0;				// [Debug] 前回の秒
			MqlDateTime time;					// [Debug] 秒を取り出す
			datetime now = TimeLocal();			// [Debug] 現在日時（ローカル時間）			
			TimeToStruct( now, time );			// [Debug] データ格納
#endif			
			/* EAでのみ管理する注文について、全情報を変数に格納 */
			for( int i = 0; i < total; i++ ){
				
				ticket	= PositionGetTicket( i );						// ポジションチケット取得（コールする儀式）
				symbol	= PositionGetString( POSITION_SYMBOL );			// シンボル
				magic	= PositionGetInteger( POSITION_MAGIC );			// マジックナンバー
				type	= (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);	// 売買タイプ
				
				// EA以外はデータを格納しない
				if( magic != MAGIC_EA ) continue;
				
				// 注文方法に応じてデータ格納
				if( type == POSITION_TYPE_BUY ){		// 買い（POSITION_TYPE_BUY）
				
					st_BuyEA.d_price[index_buy] 		= PositionGetDouble( POSITION_PRICE_OPEN );			// オープン価格
					st_BuyEA.d_volume[index_buy] 		= PositionGetDouble( POSITION_VOLUME );				// ロット
					st_BuyEA.i_digits[index_buy] 		= (int)SymbolInfoInteger( symbol,SYMBOL_DIGITS );	// 小数点以下の桁数
					st_BuyEA.l_createTime[index_buy]	= (long)PositionGetInteger(POSITION_TIME);			// 注文が出された時刻
					st_BuyEA.d_tp[index_buy]			= PositionGetDouble( POSITION_TP );					// TP
					index_buy++;		// 次のデータを格納
				} 
				else{		// 売り（POSITION_TYPE_SELL）
					
					st_SellEA.d_price[index_sell] 		= PositionGetDouble( POSITION_PRICE_OPEN );			// オープン価格
					st_SellEA.d_volume[index_sell] 		= PositionGetDouble( POSITION_VOLUME );				// ロット
					st_SellEA.i_digits[index_sell] 		= (int)SymbolInfoInteger( symbol,SYMBOL_DIGITS );	// 小数点以下の桁数
					st_SellEA.l_createTime[index_sell]	= (long)PositionGetInteger(POSITION_TIME);			// 注文が出された時刻
					st_SellEA.d_tp[index_buy]			= PositionGetDouble( POSITION_TP );					// TP
					index_sell++;		// 次のデータを格納
				}
			}
			
			/* 全注文数保管 */
			st_BuyEA.i_orderNum = index_buy;
			st_SellEA.i_orderNum = index_sell;
			
#ifdef debug_Handler
			/* [Debug] 1秒に最高1回ログ */
			if( i_sec != time.sec ){
				C_logger.output_log_to_file(
					StringFormat("買[0]%f, [1]%f, [2]%f, [3]%f, [4]%f",
									st_BuyEA.d_price[0], st_BuyEA.d_price[1], st_BuyEA.d_price[2], st_BuyEA.d_price[3], st_BuyEA.d_price[4] )
				);
				C_logger.output_log_to_file(
					StringFormat("売[0]%f, [1]%f, [2]%f, [3]%f, [4]%f",
									st_SellEA.d_price[0], st_SellEA.d_price[1], st_SellEA.d_price[2], st_SellEA.d_price[3], st_SellEA.d_price[4] )
				);
			}
			i_sec = time.sec;
#endif
		}
		
		
		// *************************************************************************
		//	機能		： 注文量に応じた利益を得るための加算する価格[USD]を取得
		//	注意		： なし
		//	メモ		： なし
		//	引数		： 注文数
		//	返り値		： 加算する価格[USD]
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.05			Taka		新規
		// 		v1.1		2021.08.08			Taka		UIの設定値に基づいて利益量を最適化
		// *************************************************************************/
		double get_profitAdd( int orderNum, ENUM_POSITION_TYPE en_type ){
			
			double ans = 0.0;
			
			/* 注文数に応じて */
			switch( orderNum ){
				
				case  1:	ans = 70;		break;
				case  2:	ans = 70;		break;
				case  3:	ans = 125;		break;
				case  4:	ans = 150;		break;
				case  5:	ans = 175;		break;
				case  6:	ans = 200;		break;
				case  7:	ans = 225;		break;
				case  8:	ans = 250;		break;
				case  9:	ans = 275;		break;
				case 10:	ans = 300;		break;
				case 11:	ans = 325;		break;
				case 12:	ans = 350;		break;
				case 13:	ans = 375;		break;
				case 14:	ans = 400;		break;
				case 15:	ans = 425;		break;
				case 16:	ans = 450;		break;
				default:	ans = 500;		break;
			}
			
			/* データコピー */
			if( en_type == POSITION_TYPE_BUY ){		// 買い（POSITION_TYPE_BUY）
				ans = ans * AM_1st_buy_width / 400.0;			// 400USDに基づく利益量のため
			}
			else{									// 売り（POSITION_TYPE_SELL）
				ans = ans * AM_1st_sell_width / 400.0;			// 400USDに基づく利益量のため
			}
			
			if( ans < 50.0 ) ans = 50.0;
			
			return ans;
		}
		
		
		// *************************************************************************
		//	機能		： 注文量に応じたスワップでマイナスにならないための追加価格[USD]を取得
		//	注意		： なし
		//	メモ		： なし
		//	引数		： 注文数
		//	返り値		： 加算する価格[USD]
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.05			Taka		新規
		// *************************************************************************/
		double get_swapAdd( int orderNum ){
			
			double ans = 0.0;
			
			/* 注文数に応じて */
			switch( orderNum ){
				
				case  1:	ans = 1;		break;
				case  2:	ans = 2;		break;
				case  3:	ans = 4;		break;
				case  4:	ans = 6;		break;
				case  5:	ans = 9;		break;
				case  6:	ans = 12;		break;
				case  7:	ans = 16;		break;
				case  8:	ans = 22;		break;
				case  9:	ans = 29;		break;
				case 10:	ans = 38;		break;
				case 11:	ans = 48;		break;
				case 12:	ans = 59;		break;
				case 13:	ans = 71;		break;
				case 14:	ans = 86;		break;
				case 15:	ans = 102;		break;
				case 16:	ans = 119;		break;
				default:	ans = 200;		break;
			}
			
			return ans;
		}
		
		
		// *************************************************************************
		//	機能		： 現在の注文から最新で設定するべきTPの値を計算する
		//	注意		： なし
		//	メモ		： なし
		//	引数		： 注文の種類（売り/買いなど）
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.05			Taka		新規
		// *************************************************************************/
		double GetNewTP( ENUM_POSITION_TYPE en_type ){
			
			double	new_tp = 0;				// TP
			stORDER	st_data;				// 取引データ
			double	d_gain = 1.0;			// 演算（Buy:1.0,Sell:-1.0）
			double	sum_volume = 0.0;		// ロット合計
			double	sum_amount = 0.0;		// 注文量合計
			double	d_profit = 0.0;			// 追加数値
			double	d_swap = 0.0;			// 追加数値
			int		i;						// loop用
			
			/* データコピー */
			if( en_type == POSITION_TYPE_BUY ){		// 買い（POSITION_TYPE_BUY）
				st_data = st_BuyEA;
				
			}
			else{									// 売り（POSITION_TYPE_SELL）
				st_data = st_SellEA;
				d_gain = -1.0;		// 演算時に使用（利益を増やすためTP価格をマイナスする）
			}
			
			/* 注文がない場合は0を返す */
			if( st_data.i_orderNum == 0 ) { 
				return 0; 
			}
			
			/* 平均単価計算 */
			for( i=0; i < st_data.i_orderNum; i++ ){
				
				sum_volume += st_data.d_volume[i];			// ロット加算
				sum_amount += st_data.d_price[i] * st_data.d_volume[i];		// 注文量加算
			}
			
			/* 利益とスワップを追加 */
			d_profit = get_profitAdd( st_data.i_orderNum, en_type );
			d_swap = get_swapAdd( st_data.i_orderNum );
			new_tp = NormalizeDouble( sum_amount / sum_volume + ( d_profit + d_swap ) * d_gain , st_data.i_digits[0] );
			
#ifdef debug_Handler
			/* [Debug] TPなど表示 */
			C_logger.output_log_to_file(
				StringFormat( "TP計算-平均単価 [売買]%d(0:buy 1:sell) [ロット合計]%f [注文量合計]%f [利益]%f [スワップ]%f [TP]%f", 
								(int)en_type, sum_volume, sum_amount, d_profit * d_gain, d_swap * d_gain, new_tp )
			);
#endif
			return new_tp;
		}
		
		
		// *************************************************************************
		//	機能		： TPを設定する
		//	注意		： なし
		//	メモ		： TPが0設定の場合には何もしない
		//	引数		： 注文の種類（売り/買いなど）、TP価格
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.05			Taka		新規
		// *************************************************************************/
		void SetTP( ENUM_POSITION_TYPE en_type, double d_tp ){
			
			int				i;							// loop用
			MqlTradeRequest	request;					// 送信データ
			MqlTradeResult	result;						// 送信結果
			int 			total = PositionsTotal();	// 全注文
			ulong			position_ticket;			// ポジションチケット(この関数コールすると、後はID指定不要)
			string 			position_symbol;			// シンボル
			ulong 			magic;						// マジックナンバー
			ENUM_POSITION_TYPE type;					// 売買タイプ
			int 			digits;						// 桁数
			
			C_logger.output_log_to_file(
				StringFormat("OrderManager::SetTP 関数スタート [売買]%d(0:buy 1:sell) [TP]%f", 
								(int)en_type, d_tp )
			);

			/* TPが0の指定の場合は設定しない */
			if( d_tp == 0 ){
				return;
			}
			
			/* TPが同一の場合設定しない */
			if( en_type == POSITION_TYPE_BUY ){		// 買い（POSITION_TYPE_BUY）
				if( st_BuyEA.d_tp[0] == NormalizeDouble( d_tp, st_BuyEA.i_digits[0] ) ){
					return;
				}
			}
			else{									// 売り（POSITION_TYPE_SELL）
				if( st_SellEA.d_tp[0] == NormalizeDouble( d_tp, st_SellEA.i_digits[0] ) ){
					return;
				}
			}			
			
			/* TPを設定 */
			for( i = total - 1; i >= 0; i-- )
			{
				/* データ取得 */
				position_ticket	= PositionGetTicket( i );		// ポジションチケット(この関数コールすると、後はID指定不要)
				position_symbol	= PositionGetString( POSITION_SYMBOL );
				magic			= PositionGetInteger( POSITION_MAGIC );
				type			= (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
				digits			= (int)SymbolInfoInteger( position_symbol,SYMBOL_DIGITS );
				
				// EAの注文でない場合はスキップ
				if( magic != MAGIC_EA ) continue;
				
				// 指定されたポジションタイプでない場合はスキップ
				if( en_type != type ) continue;
				
				// データクリア
				ZeroMemory(request);
				ZeroMemory(result);
				
				// 送信パラメータの設定
				request.action    = TRADE_ACTION_SLTP;
				request.position  = position_ticket;
				request.symbol    = position_symbol;
				request.sl        = 0;
				request.tp        = NormalizeDouble( d_tp, digits );		// ポジションのTake Profit
				request.magic     = MAGIC_EA;
					
				// リクエストの送信
				bool ans = OrderSend(request,result);

				C_logger.output_log_to_file(
					StringFormat("OrderManager::SetTP TP送信 [ans]%d", (int)ans)
				);

				if( ans == false ){
					C_logger.output_log_to_file(
						StringFormat("OrderManager::SetTP 注文送信エラー [code]%d", GetLastError())
					);
				}
			}
		}
		
		
		// *************************************************************************
		//	機能		： 最終注文した注文価格を取得する
		//	注意		： なし
		//	メモ		： なし
		//	引数		： 注文の種類（売り/買いなど）
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// 		v1.1		2021.08.04			taka		初期化処理などを見直し
		// *************************************************************************/
		double LatestOrderOpenPrice( ENUM_POSITION_TYPE req_type ){
			
			double latest_position_price = 0;		// 指定されたタイプの最後に注文したポジションの価格
			int total = PositionsTotal();			// 全保有ポジション数
			ulong position_ticket;					// 注文のチケット
			string position_symbol;					// 注文のシンボル
			ulong magic;							// マジックナンバー
			ENUM_POSITION_TYPE type;				// 注文の種類（売り/買いなど）
			
			// 指定されたタイプのポジション数をカウントし、各プライスを保持
			for( int i=0; i < total; i++ ){
				
				position_ticket	= PositionGetTicket( i );
				position_symbol	= PositionGetString( POSITION_SYMBOL );
				magic			= PositionGetInteger( POSITION_MAGIC );
				type			=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
			
				if( magic == MAGIC_EA ){
					if( req_type == type ){
						
						latest_position_price = PositionGetDouble( POSITION_PRICE_OPEN );
					}
				}
			}
			
			return latest_position_price;		// 最終価格を変更
		}
	
		// *************************************************************************
		//	機能		： オーダー数取得
		//	注意		： なし
		//	メモ		： なし
		//	引数		： 注文の種類（売り/買いなど）
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// *************************************************************************/
		int get_TotalOrderNum( ENUM_POSITION_TYPE req_type ){
			int order_num=0;//オーダー数
			int total=PositionsTotal(); //　全保有ポジション数
			
			//指定されたタイプのポジション数をカウントし、各プライスを保持
			for(int i=0; i<total; i++)
			{
				ulong position_ticket	= PositionGetTicket( i );
				ulong magic			= PositionGetInteger( POSITION_MAGIC );
				ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
			
				if(magic == MAGIC_EA){
					if( req_type == type ){
						order_num++;
					}
				}
			}
			return order_num;
		}

		// *************************************************************************
		//	機能		： 新規注文
		//	注意		： なし
		//	メモ		： 現状成行のみに対応、注文結果に応じた処理が入っている
		//	引数		： ロット数、注文の種類（売り/買いなど）
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// 		v1.1		2021.08.05			taka		リファクタリング
		// *************************************************************************/
		void OrderTradeActionDeal(double volume, ENUM_ORDER_TYPE type){
			
			MqlTradeRequest request		= {};
			MqlTradeResult result		= {};
			bool ans = false;
			
			/* 注文情報作成 */
			request.action	= TRADE_ACTION_DEAL;		// 成行注文
			request.symbol	= Symbol();					// チャートの銘柄名
			volume = NormalizeDouble( volume, 2 );		// （下準備）小数点以下第2位のまるめ
			request.volume	= volume;					// ロット数
			request.type	= type;						// 売り or 買い
			request.deviation	= 5;					// 価格からの許容偏差
			request.magic		= MAGIC_EA;				// マジックナンバー指定
			// 注文価格
			if ( type == ORDER_TYPE_BUY ){			// 成行買い注文
				
				request.price = SymbolInfoDouble(Symbol(), SYMBOL_ASK );	// 発注価格
			} 
			else if( type == ORDER_TYPE_SELL ){		// 成行売り注文
				
				request.price = SymbolInfoDouble(Symbol(), SYMBOL_BID );	// 発注価格
			}
			else{									// 成行以外の注文（パラメータ指定エラー対応）
				
				C_logger.output_log_to_file("OrderManager::OrderTradeActionDeal OrderType error "); 
				return;
			}
			
			/* 注文実行 */ 
			C_logger.output_log_to_file("OrderManager::OrderTradeActionDeal  注文開始");
			ans = OrderSend( request, result );		// 注文
			
			/* 注文結果に応じた処理 */
			if( ans == false ){
				C_logger.output_log_to_file(
					StringFormat("OrderManager::OrderTradeActionDeal  注文失敗、[エラーコード]%d",GetLastError())
				);
				return;
			}
			else{
				Sleep( 1000 );		// サーバー安定待ち
				PositionSelectByTicket(result.order);		// ポジション情報を選択（ログ出力用）
			}
			
			/* 実行結果ログ出力 */
			C_logger.output_log_to_file(
				StringFormat("OrderManager::OrderTradeActionDeal  [retcode]%u [deal]%I64u [order]%I64u [type]%d (0:buy 1:sell)",
								result.retcode, result.deal, result.order, type )
			);
			C_logger.output_log_to_file("OrderManager::OrderTradeActionDeal ordersend end");
		}
		
		
		// *************************************************************************
		//	機能		： 指定されたタイプでかつMAGICNUMBERとマッチするポジションすべて決済
		//	注意		： なし
		//	メモ		： なし
		//	引数		： req_typeは決済したい建てているポジションタイプ
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// *************************************************************************/
		void OrderTradeActionCloseAll(ENUM_POSITION_TYPE req_type){
			
			C_logger.output_log_to_file("OrderManager::OrderTradeActionCloseAll start");
			MqlTradeRequest request;
			MqlTradeResult result;
			
			int total=PositionsTotal(); //　保有ポジション数  
			C_logger.output_log_to_file(StringFormat("OrderManager::OrderTradeActionCloseAll done PositionsTotal() = %d",total));
			//--- 全ての保有ポジションをスキャン
			for(int i=total-1; i>=0; i--)
			{
				ulong  position_ticket=PositionGetTicket(i);                                     // ポジションチケット
				string position_symbol=PositionGetString(POSITION_SYMBOL);                       // シンボル
				int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);             // 小数点以下の桁数
				ulong  magic=PositionGetInteger(POSITION_MAGIC);                                 // ポジションのMagicNumber
				double volume=PositionGetDouble(POSITION_VOLUME);                                 // ポジションボリューム
				double price_open=PositionGetDouble(POSITION_PRICE_OPEN);
				ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションタイプ
	
				C_logger.output_log_to_file(StringFormat("OrderManager::OrderTradeActionCloseAll #%I64u %s  %s  %.2f  %s [%I64d] price_open=%f",
								position_ticket,
								position_symbol,
								EnumToString(type),
								volume,
								DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
								magic,
								price_open));
				//--- MagicNumberが一致している場合
				if(magic==MAGIC_EA)
				{
					//--- リクエストと結果の値のゼロ化
					ZeroMemory(request);
					ZeroMemory(result);
					//--- 操作パラメータの設定
					request.action   =TRADE_ACTION_DEAL;       // 取引操作タイプ
					request.position =position_ticket;         // ポジションチケット
					request.symbol   =position_symbol;         // シンボル
					request.volume   =volume;                   // ポジションボリューム
					request.deviation=5;                       // 価格からの許容偏差
					request.magic    =MAGIC_EA;             // ポジションのMagicNumber
					//--- ポジションタイプによる注文タイプと価格の設定
					if(type==POSITION_TYPE_BUY && type==req_type)
					{
						request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
						request.type =ORDER_TYPE_SELL;
					}
					else if(type==POSITION_TYPE_SELL && type==req_type)
					{
						request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
						request.type =ORDER_TYPE_BUY;
					}else{
						continue;
					}
					//--- 決済情報の出力
					C_logger.output_log_to_file(StringFormat("OrderManager::OrderTradeActionCloseAll Close #%I64d %s %s"
																,position_ticket,position_symbol,EnumToString(type)));
					//--- リクエストの送信
					if(!OrderSend(request,result)){
						C_logger.output_log_to_file(StringFormat("OrderManager::OrderTradeActionCloseAll OrderSend error %d",GetLastError()));
					}
					//--- 操作情報 
					C_logger.output_log_to_file(StringFormat("OrderManager::OrderTradeActionCloseAll retcode=%u  deal=%I64u  order=%I64u "
																,result.retcode,result.deal,result.order));
					//---
				}
			}
		}
				
		
		// *************************************************************************
		//	機能		： Calculate new SL for trailing stop
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： トレーリングストップ設定が発動しない場合は常に0を返す
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taka		新規
		// *************************************************************************/
		double CalculateNewSL( ENUM_POSITION_TYPE req_type, double tp ){
			//現在価格がtpよりプラス幅以上の場合はtp－プラス幅をsl値とする
			double current_ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
			double current_bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
			double trailingStop_range=GlobalVariableGet("tg_trailingStop_range");
			double SetSLFromTP_range=GlobalVariableGet("tg_SetSLFromTP_range");
			double new_sl=0.0;

			if( req_type == POSITION_TYPE_BUY ){
				//C_logger.output_log_to_file(StringFormat("OrderManager::CalculateNewSL req_type = %d current_ask=%f tp=%f range=%f",req_type,current_ask,tp,trailingStop_range));
				if( current_bid - tp >= trailingStop_range ){
					new_sl = ( (int)( current_bid - trailingStop_range) / 5) * 5.0;//細かく刻むと処理に負荷がかかるので5づつ刻む
					return new_sl;
				}else if(current_bid - tp >= SetSLFromTP_range ){
					//TPをあるレンジ超えた段階でSLをセットする
					new_sl = tp;
					return new_sl;
				}
			}
			if( req_type == POSITION_TYPE_SELL ){
				//C_logger.output_log_to_file(StringFormat("OrderManager::CalculateNewSL req_type = %d current_bid=%f tp=%f range=%f",req_type,current_bid,tp,trailingStop_range));
				if( tp - current_ask >= trailingStop_range ){
					new_sl = ( (int)(current_ask + trailingStop_range) / 5) * 5.0;//細かく刻むと処理に負荷がかかるので5づつ刻む
					return new_sl;
				}else if( tp - current_ask >= SetSLFromTP_range ){
					//TPをあるレンジ超えた段階でSLをセットする
					new_sl = tp;
					return new_sl;
				}
			}
			return new_sl;
		}
		// *************************************************************************
		//	機能		： SLTPを設定する
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taka		新規
		// *************************************************************************/
		void UpdateSLTP( ENUM_POSITION_TYPE req_type ){
			MqlTradeRequest	request;
			MqlTradeResult	result;

#ifdef AAA
			// 新しいTPを計算する(無駄な計算しないようすべての処理を下記のfor文から外に出した)
//			double new_tp = CalculateNewTP( req_type );
//			double new_sl = CalculateNewSL( req_type, new_tp);
			if(new_tp == 0){
				//C_logger.output_log_to_file(StringFormat("OrderManager::UpdateSLTP req_type = %d no position error",req_type));
				return;
			}
			// SLTPの更新処理
			int total=PositionsTotal();
			//C_logger.output_log_to_file(StringFormat("OrderManager::UpdateSLTP ★SL TPセット done PositionsTotal() = %d ",total));

			for(int i=total-1; i>=0; i--)
			{
				ulong position_ticket	= PositionGetTicket( i );		// ポジションチケット(この関数コールすると、後はID指定不要)
				string position_symbol	= PositionGetString( POSITION_SYMBOL );
				int digits			= (int)SymbolInfoInteger( position_symbol,SYMBOL_DIGITS );
				ulong magic			= PositionGetInteger( POSITION_MAGIC );
				double volume			= PositionGetDouble( POSITION_VOLUME );	
				double sl				= PositionGetDouble( POSITION_SL );
				double tp				= PositionGetDouble( POSITION_TP );
				double openprice	= PositionGetDouble( POSITION_PRICE_OPEN );
				ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

				// EAの注文でない場合はスキップ
				if( magic != MAGIC_EA ) continue;
				// 指定されたポジションタイプでない場合はスキップ
				if( req_type != type ) continue;

				//C_logger.output_log_to_file( "OrderManager::UpdateSLTP 購入価格" + (string)openprice + "今のTP=" + (string)tp + 
				//                             "新しいTP" + (string)new_tp + "今のSL=" +(string)sl + "新しいSL=" + (string)new_sl+
				//							 "ASK=" + (string)SymbolInfoDouble(Symbol(),SYMBOL_ASK) + 
				//							 "BID=" + (string)SymbolInfoDouble(Symbol(),SYMBOL_BID));
				
				bool b_trailingStop_mode = GlobalVariableGet("tg_trailingStop_mode");
				ZeroMemory(request);
				ZeroMemory(result);

				if( false == b_trailingStop_mode ){//TP更新モード
					//C_logger.output_log_to_file("OrderManager::UpdateSLTP ★TP更新モード");
					// SLが設定されていたら0に更新するため処理続行
					if( 0 == sl ){
						// TPがすでに所望の値なら何もしない
						if( tp == new_tp ) continue;
					}

					//C_logger.output_log_to_file("OrderManager::UpdateSLTP ★TPを更新をする");

					// 操作パラメータの設定
					request.action    = TRADE_ACTION_SLTP;
					request.position  = position_ticket;
					request.symbol    = position_symbol;
					request.sl        = 0;
					request.tp        = new_tp;			// ポジションのTake Profit
					request.magic     = MAGIC_EA;

				}else if( true == b_trailingStop_mode ){//トレーリングストップモード
					// 新しいSLがすでに所望の値なら何もしない
					//C_logger.output_log_to_file("OrderManager::UpdateSLTP ★トレーリングストップモード");
					// TPが設定されていたら0に更新するため処理続行
					if( 0 == tp ){
						if( req_type == POSITION_TYPE_BUY ){
							//トレーリングストップ発動無し
							if( 0 == new_sl ) continue;
							//新しいSLが大きくなるのであれば更新する。小さい場合は更新しない。
							if( sl >= new_sl ) continue;
						}
						if( req_type == POSITION_TYPE_SELL ){
							//トレーリングストップ発動無し
							if( 0 == new_sl ) continue;
							//新しいSLが小さくなるのであれば更新する。大きい場合は更新しない。ただしslが初期値の0の時は更新する
							if( 0 != sl && sl <= new_sl ) continue;
						}
					}
					//C_logger.output_log_to_file("OrderManager::UpdateSLTP ★SLを更新をする");

					// 操作パラメータの設定
					request.action    = TRADE_ACTION_SLTP;
					request.position  = position_ticket;
					request.symbol    = position_symbol;
					request.sl        = new_sl;			// ポジションのStop Loss
					request.tp        = 0;
					request.magic     = MAGIC_EA;
				}

				// リクエストの送信
				if(!OrderSend(request,result))
					C_logger.output_log_to_file(StringFormat("OrderManager::UpdateSLTP [ERROE]OrderSend error %d",GetLastError()));
				// 操作情報
				//C_logger.output_log_to_file(StringFormat("OrderManager::UpdateSLTP retcode=%u  deal=%I64u  order=%I64u"
				//                                         ,result.retcode,result.deal,result.order));
			}
#endif
		}

		// *************************************************************************
		//	機能		： test用関数
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// *************************************************************************/
		void unit_test(){
			//test(両建てして前回の値を表示する)
			if(0){
				OrderTradeActionDeal( 0.01, ORDER_TYPE_BUY);
				OrderTradeActionDeal( 0.01, ORDER_TYPE_SELL);
				OrderTradeActionDeal( 0.01, ORDER_TYPE_BUY);
				OrderTradeActionDeal( 0.01, ORDER_TYPE_SELL);
				OrderTradeActionDeal( 0.01, ORDER_TYPE_BUY);
				OrderTradeActionDeal( 0.01, ORDER_TYPE_SELL);
			}
			//test(すべて決済)
			if(0){
				OrderTradeActionCloseAll( POSITION_TYPE_BUY);
				OrderTradeActionCloseAll( POSITION_TYPE_SELL);
			}
			//test(TP更新)
			if(0){
				UpdateSLTP( POSITION_TYPE_BUY );
				UpdateSLTP( POSITION_TYPE_SELL );
			}
		}
};
COrderManager* COrderManager::m_OrderManager;