//**************************************************
// class CCheckerException
//**************************************************

//**************************************************
// インクルードファイル（include）
//**************************************************
#include "typedefine.mqh"			// 定義
#include "Configuration.mqh"		// 設定


//**************************************************
// 定義（define）
//**************************************************
class CCheckerException
{
	private:
		static CCheckerException* m_CheckerException;
		CLogger* C_logger;
//		bool B_accountOk;
		
		//プライベートコンストラクタ(他のクラスにNewはさせないぞ！！！)
		CCheckerException(){
			C_logger = CLogger::GetLog();
		}

	public:
		//	機能		： //シングルトンクラスインスタンス取得
		static CCheckerException* GetCheckerException()
		{
			if(CheckPointer(m_CheckerException) == POINTER_INVALID){
				m_CheckerException = new CCheckerException();
			}
			return m_CheckerException;
		}
		
		
		// *************************************************************************
		//	機能		： 有効期限チェック関数
		//	注意		： Tickの中で実行されるためコール回数が非常に多い
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： true: 有効期限内、false: 有効期限外
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// 		v1.1		2021.08.02			Taka		Tickの中で実行されるため処理を軽く変更
		// *************************************************************************/
		bool Chk_Expired(void){
			
			static bool ans = true;				// 有効期限確認（false: 有効期限外、true: 有効期限内）
			static int lastDay = 0xff;			// 最終確認日（初期化の値は、1~31以外なら何でもOK）
			datetime start;						// 利用開始日 
			datetime end;						// 利用終了日
			datetime now = TimeLocal();			// 現在日時（ローカル時間）
			MqlDateTime temp;					// 現在日時（演算用）
			
			// 1回でも有効期限切れを検知したらずっと有効期限切れ
			if( ans == false ) {
				return false;
			}
			
			// その日初めてのチェック（同日ならばチェック不要）
			TimeToStruct( now, temp );		// 演算用データ作成
			if( lastDay == temp.day ){		// 最終確認日と現在の日にちが同じなら
				return ans;			// 前回の結果と同様のものを返す（tureしかない）
			}
			
			/* 最終確認日と現在の日にちが異なっていた場合に確認(1回目は確実この関数内に入る) */

			// 有効期限入手
			start = StringToTime( EA_START_DATE );		// 利用開始日 
			end = StringToTime( EA_END_DATE );			// 利用終了日

			// 有効期限判定
			if( ( start < now ) && ( now < end ) ){		// 期限内
				ans = true;
			}
			else{
				C_logger.output_log_to_file("CCheckerException::Chk_Expired 有効期限外");
				ans = false;
			}
			
			lastDay = temp.day;		// 最終確認日を更新
			
			return ans;				// 結果を返す
		}
		

#ifdef ADD_CheckerException
		string Get_chkAccountState(void){
			
			if( B_accountOk == true ){
				return "口座有効";
			}
			else{
				return "口座無効";
			}
		}
#endif
		
		
		// *************************************************************************
		//	機能		： 口座番号チェック関数
		//	注意		： なし
		//	メモ		： なし
		//	引数		： なし
		//	返り値		： true: 対象口座、false: 非対象口座
		//	参考URL		： なし
		// **************************	履	歴	************************************
		// 		v1.0		2021.04.14			Taji		新規
		// 		v1.1		2021.08.02			Taka		[バグ対応] ArrayBsearchの引数に入れる配列を昇順に変更
		// *************************************************************************/
		bool Chk_Account(void){

			// 引数
			long account = AccountInfoInteger( ACCOUNT_LOGIN );		// 口座番号取得
			long temp_arrary[ COUNT_OF_ARRAY( account_array ) ];	// 口座の一時配列（昇順用ソート使用）
			int near_account = 0;									// 近いアカウント配列番号
			
			// 変数初期化
			ArrayInitialize( temp_arrary, 0 );		// '0'で初期化
#ifdef debug_CheckerException
			C_logger.output_log_to_file( "[口座確認] 配列初期化");
			for( int i = 0; i < COUNT_OF_ARRAY( account_array ); i++ ){
				C_logger.output_log_to_file( "一時配列" + (string)i + ":" + (string)temp_arrary[i] );
			}
#endif			
			// 一時配列にデータコピー
			ArrayCopy( temp_arrary, account_array, 0, 0, WHOLE_ARRAY );
#ifdef debug_CheckerException
			C_logger.output_log_to_file( "[口座確認] 配列コピー");
			for( int i = 0; i < COUNT_OF_ARRAY( account_array ); i++ ){
				C_logger.output_log_to_file( "元" + (string)i + ":" + (string)account_array[i] + " 新:" + (string)temp_arrary[i] );
			}
#endif
			// 昇順に口座番号をソート
			ArraySort( temp_arrary );
#ifdef debug_CheckerException
			C_logger.output_log_to_file( "[口座確認] 昇順ソート");
			for( int i = 0; i < COUNT_OF_ARRAY( account_array ); i++ ){
				C_logger.output_log_to_file( "元" + (string)i + ":" + (string)account_array[i] + " 新:" + (string)temp_arrary[i] );
			}
#endif
			// 最も近い口座を取得
			near_account = ArrayBsearch( temp_arrary, account );
#ifdef debug_CheckerException
			C_logger.output_log_to_file( "[口座確認] 検索結果");
			C_logger.output_log_to_file("番号:" + (string)near_account + "検索口座番号:" + (string)account + " 一番近い口座番号:" + (string)temp_arrary[near_account] );
#endif
			// 口座チェック
			C_logger.output_log_to_file( "[口座確認] 起動対象の口座番号か？");
			if( account == temp_arrary[near_account] ){		// 同一ID
				C_logger.output_log_to_file("CCheckerException::Chk_Account 起動対象: " + (string)account );
//				B_accountOk = true;
				return true;
			}
			else{
				C_logger.output_log_to_file("CCheckerException::Chk_Account 起動対象ではない -> EA終了 ");
//				B_accountOk = false;
				return false;
			}
		}
};
CCheckerException* CCheckerException::m_CheckerException;