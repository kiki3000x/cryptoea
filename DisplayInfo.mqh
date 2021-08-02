//**************************************************
// class CDisplayInfo
//**************************************************
#include "Configuration.mqh"

class CDisplayInfo
{
	private:
		static CDisplayInfo* m_DisplayInfo;
		//プライベートコンストラクタ(他のクラスにNewはさせないぞ！！！)
		CDisplayInfo(){}
		// 注文情報
		class OrderInfo
		{
		public:
			int total_cnt;
			int buy_cnt;
			int sell_cnt;
		};
		OrderInfo OrderNow;						// 現状の注文状態（Tickごとに更新）
	public:
		//	機能		： //シングルトンクラスインスタンス取得
		static CDisplayInfo* GetDisplayInfo()
		{
			if(CheckPointer(m_DisplayInfo) == POINTER_INVALID){
				m_DisplayInfo = new CDisplayInfo();
			}
			return m_DisplayInfo;
		}

		// *************************************************************************
		//	機能		： 注文情報を更新する
		//	注意		： なし
		//	メモ		： Tickごとに実行する
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taka		新規
		// *************************************************************************/
		void UpdateOrderInfo( void ){
		
			int total		= PositionsTotal(); // 保有ポジション数
			int total_buy	= 0;				// 買いの保有ポジション数
			int total_sell	= 0;				// 売りの保有ポジション数
			ulong position_ticket;				// ポジションチケット
			ENUM_POSITION_TYPE type;			// ポジションタイプ

			// 注文数を計算
			for(int i=0; i<total; i++)
			{
				// 注文パラメータ取得
				position_ticket	= PositionGetTicket( i );										// ポジションチケット(この関数コールすると、後はID指定不要)
				type			= (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); 		// ポジションタイプ
			
				// 注文数をカウント
				if( type == POSITION_TYPE_BUY){
					total_buy++;
				}
				else {
					total_sell++;
				}
			}
		
			OrderNow.total_cnt = total;
			OrderNow.buy_cnt = total_buy;
			OrderNow.sell_cnt = total_sell;
		}


		// *************************************************************************
		//	機能		： チャート上にコメントを表示する
		//	注意		： なし
		//	メモ		： Tickごとに実行する
		//	引数		： なし
		//	返り値		： なし
		//	参考URL		： https://yukifx.web.fc2.com/sub/reference/05_common_func/cone/commonfunc_comment.html
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taka		新規
		// *************************************************************************/
		void ShowData( void ){
			// 表示 （注）Comment()を複数コールすると、最後の文字列しか表示されない
			Comment(
				"[SYSTEM Version] ", EA_STAGE, " Ver." + EA_VERSION, "\n",
				"[口座番号] ", (string)AccountInfoInteger( ACCOUNT_LOGIN ), "\n",
				"[有効期限] ", EA_END_DATE, "\n",
//				"\n"
//				"[注文数] " + (string)OrderNow.total_cnt +" [買い注文数]" + (string)OrderNow.buy_cnt +" [売り注文数]" + (string)OrderNow.sell_cnt,
				"\n"
			);
			//	Comment("test1" ,"test2 \n");		// sample
		}
};
CDisplayInfo*           CDisplayInfo::m_DisplayInfo;