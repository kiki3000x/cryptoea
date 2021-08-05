//**************************************************
// class COrderManager
//**************************************************
#include "Logger.mqh"
#include "Configuration.mqh"

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
			return m_OrderManager;
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
			
				if( magic == MAGICNUM ){
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
			
				if(magic == MAGICNUM){
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
			
			volume = NormalizeDouble( volume, 2 );		// 小数点以下第2位のまるめ
			
			request.action	= TRADE_ACTION_DEAL;		// 成行注文
			request.symbol	= Symbol();					// チャートの銘柄名
			request.volume	= volume;					// ロット数
			request.type	= type;						// 売り or 買い
			
			/* ----------- */
			/* 注文情報作成 */
			/* ----------- */
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
			request.deviation	= 5;				// 価格からの許容偏差
			request.magic		= MAGICNUM;			// マジックナンバー指定
			
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
				if(magic==MAGICNUM)
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
					request.magic    =MAGICNUM;             // ポジションのMagicNumber
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
		//	機能		： Calculate new TP
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taka		新規
		// *************************************************************************/
		double CalculateNewTP( ENUM_POSITION_TYPE req_type ){
			int		position_num				= 0;		// 保有ポジション数
			double	position_price_array[16]	= {0};		// 各ポジションの価格
			double	position_volume_array[16]	= {0};		// 各ポジションのロット
			int		position_digits_array[16]	= {0};		// 各ポジションの小数点以下の桁数
			long	create_time_array[16]		= {0};		// 各ポジションの注文が出された時刻
			int		total = PositionsTotal();				// 全てのポジション数取得
			double	new_tp						=	0;		// TP
			ulong position_ticket;							// ポジションチケット取得（コールする儀式）
			string position_symbol;							// シンボル
			ulong magic;									// マジックナンバー
			ENUM_POSITION_TYPE type;						// 売買タイプ
						
			/* 各ポジション情報を格納 */
			for( int i = 0; i < total; i++ ){
				
				position_ticket	= PositionGetTicket( i );							// ポジションチケット取得（コールする儀式）
				position_symbol	= PositionGetString( POSITION_SYMBOL );				// シンボル
				magic			= PositionGetInteger( POSITION_MAGIC );				// マジックナンバー
				type	= (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);	// 売買タイプ
				
				// EAの場合は値格納
				if(magic == MAGICNUM){
					if( req_type == type ){
						position_price_array[position_num] 	= PositionGetDouble( POSITION_PRICE_OPEN );					// オープン価格
						position_volume_array[position_num] = PositionGetDouble( POSITION_VOLUME );						// ロット
						position_digits_array[position_num] = (int)SymbolInfoInteger( position_symbol,SYMBOL_DIGITS );	// 小数点以下の桁数
						create_time_array[position_num] 	= (long)PositionGetInteger(POSITION_TIME);					// 注文が出された時刻
						position_num++;																					// 次のデータへ
					}
				}
			}
			
			/* ポジション数がないときには何もしない */
			if(0 == position_num){
				//C_logger.output_log_to_file("OrderManager::CalculateNewTP [ERROR]UpdateTP Position nothing ");
				return 0;
			}
			
			/* =========== */
			/* TPの更新処理 */
			/* =========== */
			int array_num = tbl_TP[position_num-1].specify_price_num;   // いくつめの注文価格に合わせるか
			double alpha = tbl_TP[position_num-1].alpha;
			double swap;												// スワップ
			double profit;												// 利益
			
			/* スワップと利益の設定 */
			if( position_num == 1 ) 		{ swap = 1;		profit = 70;	}
			else if( position_num == 2 ) 	{ swap = 2;		profit = 70;	}
			else if( position_num == 3 ) 	{ swap = 4;		profit = 125;	}
			else if( position_num == 4 ) 	{ swap = 6;		profit = 150;	}
			else if( position_num == 5 ) 	{ swap = 9;		profit = 175;	}
			else if( position_num == 6 ) 	{ swap = 12;	profit = 200;	}
			else if( position_num == 7 ) 	{ swap = 16;	profit = 225;	}
			else if( position_num == 8 ) 	{ swap = 22;	profit = 250;	}
			else if( position_num == 9 ) 	{ swap = 29;	profit = 275;	}
			else if( position_num == 10 )	{ swap = 38;	profit = 300;	}
			else if( position_num == 11 )	{ swap = 48;	profit = 325;	}
			else if( position_num == 12 ) 	{ swap = 59;	profit = 350;	}
			else if( position_num == 13 ) 	{ swap = 71;	profit = 375;	}
			else if( position_num == 14 ) 	{ swap = 86;	profit = 400;	}
			else if( position_num == 15 ) 	{ swap = 102;	profit = 425;	}
			else if( position_num == 16 ) 	{ swap = 119;	profit = 450;	}
			else 							{ swap = 200;	profit = 500;	}
			
			/* 符号反転→SELLの場合 */
			if( req_type == POSITION_TYPE_SELL ){
				swap = -swap;
				profit = -profit;
			}
			
			/* TP計算(平均単価ベース) */
			double sum_volume = 0.0;
			double sum_amount = 0.0;
			for(int j=0; j<position_num; j++ ){
				
				sum_volume += position_volume_array[j];
				sum_amount += position_price_array[j] * position_volume_array[j];
			}
			
			C_logger.output_log_to_file(
				StringFormat( "結果： #%I64d %s %s", position_num, position_symbol, EnumToString(type) )
			);
			
			new_tp = NormalizeDouble( sum_amount / sum_volume + profit + swap, position_digits_array[0] );
			
//			C_logger.output_log_to_file( "OrderManager::CalculateNewTP " + (string)array_num + "つ目の注文価格 = " 
//										+(string)(sum_amount / sum_volume) + " profit = " + (string)profit + " swap = " + (string)swap );
			
			return new_tp;
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

			// 新しいTPを計算する(無駄な計算しないようすべての処理を下記のfor文から外に出した)
			double new_tp = CalculateNewTP( req_type );
//			double new_sl = CalculateNewSL( req_type, new_tp);
			if(new_tp == 0){
				//C_logger.output_log_to_file(StringFormat("OrderManager::UpdateSLTP req_type = %d no position error",req_type));
				return;
			}
#ifdef AAA
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
				if( magic != MAGICNUM ) continue;
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
					request.magic     = MAGICNUM;

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
					request.magic     = MAGICNUM;
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