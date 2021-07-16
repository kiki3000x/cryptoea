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
		//	機能		： 初期化　オーダーが残存している場合は、前回注文した注文価格を取得し保持する
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// *************************************************************************/
		double LatestOrderOpenPrice( ENUM_POSITION_TYPE req_type ){
			double latest_position_price = 0; //　指定されたタイプの最後に注文したポジションの価格

			int total=PositionsTotal(); //　全保有ポジション数
			
			//指定されたタイプのポジション数をカウントし、各プライスを保持
			for(int i=0; i<total; i++)
			{
				ulong position_ticket	= PositionGetTicket( i );
				string position_symbol	= PositionGetString( POSITION_SYMBOL );
				ulong magic				= PositionGetInteger( POSITION_MAGIC );
				ENUM_POSITION_TYPE type	=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
			
				if(magic == MAGICNUM){
					if( req_type == type ){
						latest_position_price = PositionGetDouble( POSITION_PRICE_OPEN );
					}
				}
			}
			return latest_position_price;
		}
	
		// *************************************************************************
		//	機能		： オーダー数取得
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
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
		//	機能		： 新規成り行き注文
		//	注意		： なし
		//	メモ		： なし
		//	引数		： req:ポジションタイプ
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			taji		新規
		// *************************************************************************/
		void OrderTradeActionDeal(double volume, ENUM_ORDER_TYPE type){
			MqlTradeRequest request = {};
			MqlTradeResult result={};

			request.action   =TRADE_ACTION_DEAL;
			request.symbol   =Symbol();
			request.volume   =volume; // ロット数
			request.type     =type;

			if ( ORDER_TYPE_BUY == type){
				request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK); // 発注価格
			} else if( ORDER_TYPE_SELL == type ){
				request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID);
			}else{
				C_logger.output_log_to_file("OrderManager::OrderTradeActionDeal OrderType error "); 
				return;
			}

			request.deviation=5;// 価格からの許容偏差
			request.magic=MAGICNUM;                          

			C_logger.output_log_to_file("OrderManager::OrderTradeActionDeal ordersend start");
			if(!OrderSend(request,result)){
				C_logger.output_log_to_file(StringFormat("OrderManager::OrderTradeActionDeal OrderSend error %d",GetLastError()));  
				return;
			}else{
				Sleep(1000);
				PositionSelectByTicket(result.order);
			}
			C_logger.output_log_to_file(StringFormat("OrderManager::OrderTradeActionDeal retcode=%u  deal=%I64u  order=%I64u  type=%d[0:buy 1:sell]"
			                                         ,result.retcode,result.deal,result.order,type));
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
			int position_num=0; //　指定されたタイプの保有ポジション数
			double position_price_array[16]={0}; //　指定されたタイプの各ポジションの価格
			double position_volume_array[16]={0}; //　指定されたタイプの各ロットの価格
			int position_digits_array[16]={0}; //　指定されたタイプの各ポジションの小数点以下の桁数
			long create_time_array[16]={0}; //　指定されたタイプの各ポジションの小数点以下の桁数
			
			//C_logger.output_log_to_file("OrderManager::CalculateNewTP start");

			//全てのポジション数取得
			int total=PositionsTotal();
			for(int i=0; i<total; i++)
			{
				ulong position_ticket	= PositionGetTicket( i );
				string position_symbol	= PositionGetString( POSITION_SYMBOL );
				ulong magic			= PositionGetInteger( POSITION_MAGIC );
				ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
			
				if(magic == MAGICNUM){
					if( req_type == type ){
						position_price_array[position_num] = PositionGetDouble( POSITION_PRICE_OPEN );
						position_volume_array[position_num] = PositionGetDouble( POSITION_VOLUME );
						position_digits_array[position_num] = (int)SymbolInfoInteger( position_symbol,SYMBOL_DIGITS );// 小数点以下の桁数
						create_time_array[position_num] = (long)PositionGetInteger(POSITION_TIME);
						position_num++;
					}
				}
			}

			//C_logger.output_log_to_file(StringFormat("OrderManager::CalculateNewTP position_num = %d req_type = %d"
			//                                         ,position_num, req_type));
			
			//リクエストされたタイプのポジションは0
			if(0 == position_num){
				//C_logger.output_log_to_file("OrderManager::CalculateNewTP [ERROR]UpdateTP Position nothing ");
				return 0;
			}

			// テーブルに従ってTPの更新値を決定
			int array_num = tbl_TP[position_num-1].specify_price_num;   //いくつめの注文価格に合わせるか
			double alpha = tbl_TP[position_num-1].alpha;

			//alphaの符号反転→SELLの場合
			if( req_type == POSITION_TYPE_SELL ) alpha = -alpha;

			double new_tp=0;

			//TP計算
			if(1){
				int boundary_for_caluculation_num =5;

				if(Config_tp_calculation_mode == TP_CALCULATION_MODE_TAJI){//★変更taji
					boundary_for_caluculation_num = 2;
				}

				if( position_num > boundary_for_caluculation_num ){		// 4つ以上注文があったら(デフォルト)
					// 少しでもプラスになったら約定
					double sum_volume = 0.0;
					double sum_amount = 0.0;
					
					for(int j=0; j<position_num; j++ ){
						sum_volume += position_volume_array[j];
						sum_amount += position_price_array[j] * position_volume_array[j];
					}
					new_tp = NormalizeDouble( sum_amount / sum_volume, position_digits_array[0] ) + alpha;
					
				}else{
					// 始めの価格と最後の価格の平均値＋αに設定
					new_tp = ( position_price_array[0] + position_price_array[ position_num - 1] ) / 2;
					new_tp = NormalizeDouble( new_tp + alpha, position_digits_array[array_num-1] );
				}
				//C_logger.output_log_to_file( "OrderManager::CalculateNewTP " + (string)array_num + "つ目の注文価格 = " 
				//							+(string)position_price_array[array_num-1] + " alpha = " + (string)alpha );
			}

			//(test)5つ以上ポジション保持してから経過日時×100USDづつnew_tpを損する方向へずらす(2日以上経過したら発動)
			/*if(Config_tp_calculation_mode == TP_CALCULATION_MODE_TAJI){//★変更taji
				long current_time = (long)TimeCurrent();
				if( position_num > 4 ){//ポジション5つ以上　3つ→0番　4つ→1番
					if ( current_time - create_time_array[position_num-5] > 86400 ){
						
						int shift_days = (current_time - create_time_array[position_num-3]) / 86400;
						double shift_tp = 100.0 * (shift_days - 1);

						//SELLの場合はマイナス反転
						if( req_type == POSITION_TYPE_SELL ) shift_tp = -shift_tp;

						new_tp = new_tp - shift_tp;
					}
				}
			}*/
			//C_logger.output_log_to_file(StringFormat("  create_time_array[0] = %d current_time = %d", create_time_array[0],current_time));

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

			//新しいTPを計算する(無駄な計算しないようすべての処理を下記のfor文から外に出した)
			double new_tp = CalculateNewTP( req_type );
			double new_sl = CalculateNewSL( req_type, new_tp);
			if(new_tp == 0){
				//C_logger.output_log_to_file(StringFormat("OrderManager::UpdateSLTP req_type = %d no position error",req_type));
				return;
			}

			//SLTPの更新処理
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