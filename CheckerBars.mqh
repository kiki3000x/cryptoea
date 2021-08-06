//**************************************************
// class CCheckerBars
//**************************************************
#include "Configuration.mqh"
//**************************************************
// 定義（define）
//**************************************************
class CCheckerBars
{
	private:
		static CCheckerBars* m_CheckerBars;
		CLogger*             C_logger;
		
		//プライベートコンストラクタ(他のクラスにNewはさせないぞ！！！)
		CCheckerBars(){
			C_logger = CLogger::GetLog();
		}

	public:
		//	機能		： //シングルトンクラスインスタンス取得
		static CCheckerBars* GetCheckerBars(){
			if(CheckPointer(m_CheckerBars) == POINTER_INVALID){
				m_CheckerBars = new CCheckerBars();
			}
			return m_CheckerBars;
		}
		
		
		// *************************************************************************
		//	機能		： 急激な価格変化の有無を確認
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： false: 急激な変化なし、ture: 急激な変化あり
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.08.06			Taka		新規
		// *************************************************************************/
		bool Is_warningPriceDiv(void){
			
			double OpenArray[MAX_CHK_MINUTES + 1]	={0};		// オープン価格
			double CloseArray[MAX_CHK_MINUTES + 1]	={0};		// クローズ価格
			double diff_latest;									// 最近の差分
			double diff_pre1;									// 1つ前の差分
			
			/* 急激変化の機能 */
			if( ES_BigDivMode == false ){
				return false;
			}	
			
			/* Barの取得 */
			for( int i = 0; i < MAX_CHK_MINUTES + 1; i++ ){
				OpenArray[i] = iOpen( Symbol(), PERIOD_M1, i );			// 1分足取得
				CloseArray[i] = iClose( Symbol(), PERIOD_M1, i );		// 1分足取得
			}
			
			/* 1分チェック */
			diff_latest = OpenArray[0] - CloseArray[0];			// 最新のBar
			diff_pre1   = OpenArray[1] - CloseArray[1];			// 1つ前のBar
			if( diff_latest > ES_PriceDiv1min ||  diff_pre1 > ES_PriceDiv1min ){
				// 下落局面なので最低BUYは控える(過去‐現在が＋なので過去が高い、現在が低い→下落)
//				return RECOMMEND_STOP_BUY_DEAL;
				return true;		// 急激変化あり
			}
			if( -diff_latest > ES_PriceDiv1min ||  -diff_pre1 > ES_PriceDiv1min ){
//				return RECOMMEND_STOP_SELL_DEAL;
				return true;		// 急激変化あり
			}
			
			/* 5分チェック */
			diff_latest = OpenArray[5] - CloseArray[1];		// 5つ前の1分足のオープン価格から1つ前のクローズ価格の差分
			diff_pre1   = OpenArray[4] - CloseArray[0];		// 1つ前のBar
			if( diff_latest > ES_PriceDiv5min ||  diff_pre1 > ES_PriceDiv5min ){
				// 下落局面なので最低BUYは控える(過去‐現在が＋なので過去が高い、現在が低い→下落)
//				return RECOMMEND_STOP_BUY_DEAL;
				return true;		// 急激変化あり
			}
			if( -diff_latest > ES_PriceDiv5min || -diff_pre1 > ES_PriceDiv5min ){
//				return RECOMMEND_STOP_SELL_DEAL;
				return true;		// 急激変化あり
			}
			
			/* カスタムチェック */
			diff_latest = OpenArray[ES_PriceDivnmin_num] - CloseArray[1];  //3つ前の1分足のオープン価格から1つ前のクローズ価格の差分
			diff_pre1   = OpenArray[ES_PriceDivnmin_num-1] - CloseArray[0];//1つ前のBar
			if( diff_latest > ES_PriceDivnmin || diff_pre1 > ES_PriceDivnmin ){
				// 下落局面なのでBUYは控える(過去‐現在が＋なので過去が高い、現在が低い→下落)
//				return RECOMMEND_STOP_BUY_DEAL;
				return true;		// 急激変化あり
			}
			if( -diff_latest > ES_PriceDivnmin || -diff_pre1 > ES_PriceDivnmin ){
//				return RECOMMEND_STOP_SELL_DEAL;
				return true;		// 急激変化あり
			}
			
			return false;
		}
		
		
		// *************************************************************************
		//	機能		： スーパー下落局面は突然戻る可能性があるのでSELLは控える、スーパー高騰局面は突然戻る可能性があるのでBUYは控える
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： 
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// *************************************************************************/
		/*int Chk_preiod_m1_bars_stoporder(void){
			int shift=0;
			double range = GlobalVariableGet("tg_StopOrderJudge_range");
			int minutes = GlobalVariableGet("tg_StopOrderJudge_minutes");
			double OpenArray[ 1024 ]={0};
			double CloseArray[ 1024 ]={0};
			//配列崩壊防止
			if( minutes >= 1024 ){
				return false;
			}
			//Barの取得
			for( int i = 0; i < minutes+1; i++){
				OpenArray[i] = iOpen(Symbol(),PERIOD_M1,i);
				CloseArray[i] = iClose(Symbol(),PERIOD_M1,i);
			}

			double diff_latest;
			double diff_pre1;

			//カスタムチェック(デフォルト10分)
			diff_latest = OpenArray[minutes] - CloseArray[1];  //3つ前の1分足のオープン価格から1つ前のクローズ価格の差分
			diff_pre1   = OpenArray[minutes-1] - CloseArray[0];//1つ前のBar
			if( diff_latest > range || diff_pre1 > range ){
				//C_logger.output_log_to_file(StringFormat("CCheckerBars::Chk_preiod_m1_bars %d分値幅チェック下落局面 diff_latest = %f OpenArray[10] = %f CloseArray[1] = %f"
				//                            ,NUM_MINUTES_CUSTOM,diff_latest,OpenArray[NUM_MINUTES_CUSTOM],CloseArray[1]));
				//スーパー下落局面は突然戻る可能性があるのでSELLは控える(過去‐現在が＋なので過去が高い、現在が低い→下落)
				return RECOMMEND_STOP_SELL_DEAL;
			}
			if( -diff_latest > range || -diff_pre1 > range ){
				//C_logger.output_log_to_file(StringFormat("CCheckerBars::Chk_preiod_m1_bars %d分値幅チェック上昇局面 diff_latest = %f OpenArray[10] = %f CloseArray[1] = %f"
				//                            ,NUM_MINUTES_CUSTOM,diff_latest,OpenArray[NUM_MINUTES_CUSTOM],CloseArray[1]));
				return RECOMMEND_STOP_BUY_DEAL;
			}

			return RECOMMEND_NO_PROBREM;
		}*/
};
CCheckerBars* CCheckerBars::m_CheckerBars;