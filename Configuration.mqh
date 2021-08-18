// *************************************************************************
//   システム	： CryptoEA
//   概要		： EA用の設定ファイル
//   注意		： なし
//   メモ		： Configurationパターン切り替え定義により動作を変える
// **************************    履    歴    *******************************
// 		v1.0		2021.04.14			Taji		新規
// 		v1.1		2021.08.02			Taka		Configuration切り替えリファクタ
// *************************************************************************/
// 多重コンパイル抑止
#ifndef _CONFIG_H
#define _CONFIG_H

//**************************************************
// Configurationパターン切り替え（適用しない方はコメントアウト）
//**************************************************
#define CONFICRATION_PATERN_TAKA			// TAKA用パラメータ適用
//#define CONFICRATION_PATERN_****			// ****用パラメータ適用


#ifdef CONFICRATION_PATERN_TAKA
// *************************************************************************
//  CONFICRATION_PATERN_TAKA（TAKA用パラメータ設定）
// *************************************************************************

//**************************************************
// インクルードファイル（include）
//**************************************************

//**************************************************
// 定義（define）
//**************************************************
/* バージョン表示 */
#define EA_STAGE		"MASTER-20210809a"		// ステージ表示
#define EA_VERSION		"1.20"					// バージョン表示

/* 有効期限の設定 */
#define EA_START_DATE	"2020.04.01 00:00"		// EA利用開始日時、※ 期間外はフェードアウトモードへ移行
#define EA_END_DATE		"2021.08.31 23:59"		// EA利用終了日時、※ 期間外はフェードアウトモードへ移行

/* 口座番号のチェック */
#define SPECIFIED_ACCOUNT_CHECK		true		// 指定口座でのみ動作: true：有効(default)、false：無効

/* マジックナンバー */
#define MAGIC_EA			( 0x0001 )				// EA用の注文指定
#define MAGIC_NM			( 0x0002 )				// 通常用のナンピン指定
#define MAGIC_AT			( 0x0004 )				// アタッカー用のナンピン指定
#define MAGIC_BL			( 0x0008 )				// バランサー用のナンピン指定
#define SET_MAGIC_NM(a)		( ( a ) | MAGIC_NM )	// 通常用のナンピン設定
#define SET_MAGIC_AT(a)		( ( a ) | MAGIC_AT )	// アタッカー用のナンピン設定
#define SET_MAGIC_BL(a)		( ( a ) | MAGIC_BL )	// バランサー用のナンピン設定
#define IS_MAGIC_EA(a)		( ( ( a ) & MAGIC_EA ) == 0 ? false : true )	// EA用の注文判定
#define IS_MAGIC_NM(a)		( ( ( a ) & MAGIC_NM ) == 0 ? false : true )	// 通常用のナンピン判定
#define IS_MAGIC_AT(a)		( ( ( a ) & MAGIC_AT ) == 0 ? false : true )	// アタッカー用のナンピン判定
#define IS_MAGIC_BL(a)		( ( ( a ) & MAGIC_BL ) == 0 ? false : true )	// バランサー用のナンピン判定

/* ロット設定 */
#define BASE_LOT					(0.01)		// システム上の最小ロット数
#define MAX_ORDER_NUM		 		(10)		// 注文追加数制限
#define MAX_EA_NUM					(16)		// EAで管理する片側注文（BUY/SELL）の最大注文数
#define ORDER_LOT_GAIN				(1.278)		// 注文のロット増加比率

/* 注文幅設定 */
#define MAX_DIFF_PRICE_LIST_NUM		(16)		// ピン幅リストのリスト数
#define BASE_DIFF_PRICE				(50)

/* 急激な価格変動の検知時に、新規注文を入れない */
#define MAX_CHK_MINUTES				90			// カスタムチェックの期間
												//(この値はチェックする最大の値にすること ）
												// ※ 最大配列Noに使っているためOutOfRangeErrorの原因になるため

/* デバッグ文字表示（表示しない場合はコメントアウト） */
//#define debug_CheckerException				// 稼働チェック
//#define debug_Configuration					// 設定
#define debug_Handler							// 動作管理
#define debug_OrderManager						// 取引管理


//**************************************************
// 列挙体（enum）
//**************************************************

//**************************************************
// 構造体（struct）
//**************************************************

//**************************************************
// グローバル変数
//**************************************************
/* 口座番号の登録（番号の順番はランダムでもOK、SPECIFIED_ACCOUNT_CHECK 有効時にチェック入る） */
const long account_array[] = {
	175069,			// 20210815_T.T-BTC
	172424,			// 20210801_Y.I-BTC
	173883,			// 20210802_Y.I-BTC
	205608,			// 20210814_Y.I-ADA
	1257711,		// 20210801
	1257721,		// 20210801
	1257741,		// 20210801
	1257601,		// 20210802
	1257701,		// 20210802
	1257731,		// 20210803
};

/* ピン幅リスト（ConfigCustomizeDiffPriceOrderList()で最終値を設定） */
int diff_buy_price_order[] = {		// 暫定で初期値入れています
	BASE_DIFF_PRICE + 120,			// 01-02ピン間の価格差
	BASE_DIFF_PRICE + 120 * 2,		// 02-03ピン間の価格差
	BASE_DIFF_PRICE + 120 * 3,		// 03-04ピン間の価格差
	BASE_DIFF_PRICE + 120 * 4,		// 04-05ピン間の価格差
	BASE_DIFF_PRICE + 120 * 5,		// 05-06ピン間の価格差
	BASE_DIFF_PRICE + 120 * 6,		// 06-07ピン間の価格差
	BASE_DIFF_PRICE + 120 * 7,		// 07-08ピン間の価格差
	BASE_DIFF_PRICE + 120 * 8,		// 08-09ピン間の価格差
	BASE_DIFF_PRICE + 120 * 9,		// 09-10ピン間の価格差
	BASE_DIFF_PRICE + 120 * 10,		// 10-11ピン間の価格差
	BASE_DIFF_PRICE + 120 * 11,		// 11-12ピン間の価格差
	BASE_DIFF_PRICE + 120 * 12,		// 12-13ピン間の価格差
	BASE_DIFF_PRICE + 120 * 13,		// 13-14ピン間の価格差
	BASE_DIFF_PRICE + 120 * 14,		// 14-15ピン間の価格差
	BASE_DIFF_PRICE + 120 * 15,		// 15-16ピン間の価格差
	BASE_DIFF_PRICE + 120 * 16,		// 16-17ピン間の価格差
};
int diff_sell_price_order[] = {		// 暫定で初期値入れています
	BASE_DIFF_PRICE + 120,			// 01-02ピン間の価格差
	BASE_DIFF_PRICE + 120 * 2,		// 02-03ピン間の価格差
	BASE_DIFF_PRICE + 120 * 3,		// 03-04ピン間の価格差
	BASE_DIFF_PRICE + 120 * 4,		// 04-05ピン間の価格差
	BASE_DIFF_PRICE + 120 * 5,		// 05-06ピン間の価格差
	BASE_DIFF_PRICE + 120 * 6,		// 06-07ピン間の価格差
	BASE_DIFF_PRICE + 120 * 7,		// 07-08ピン間の価格差
	BASE_DIFF_PRICE + 120 * 8,		// 08-09ピン間の価格差
	BASE_DIFF_PRICE + 120 * 9,		// 09-10ピン間の価格差
	BASE_DIFF_PRICE + 120 * 10,		// 10-11ピン間の価格差
	BASE_DIFF_PRICE + 120 * 11,		// 11-12ピン間の価格差
	BASE_DIFF_PRICE + 120 * 12,		// 12-13ピン間の価格差
	BASE_DIFF_PRICE + 120 * 13,		// 13-14ピン間の価格差
	BASE_DIFF_PRICE + 120 * 14,		// 14-15ピン間の価格差
	BASE_DIFF_PRICE + 120 * 15,		// 15-16ピン間の価格差
	BASE_DIFF_PRICE + 120 * 16,		// 16-17ピン間の価格差
};


//**************************************************
// プロトタイプ宣言（ファイル内で必要なものだけ記述）
//**************************************************


// *************************************************************************
//	機能		： ピン幅リストのカスタマイズ
//	注意		： なし
//	メモ		： Handlerのinitでコール
//	引数		： なし
//	返り値		： なし
//	参考URL		： なし
// **************************	履	歴	************************************
// 		v1.0		2021.08.08			Taka		新規
// *************************************************************************/
void ConfigCustomizeDiffPriceOrderList(void){

	double d_base = (double)AM_1st_buy_width;
	
	/* 値幅を設定 */
	diff_buy_price_order[0] = (int)NormalizeDouble( d_base * 1.000, 0 );		// 1-2ピン間の価格差
	diff_buy_price_order[1] = (int)NormalizeDouble( d_base * 1.375, 0 );		// 2-3ピン間の価格差
	diff_buy_price_order[2] = (int)NormalizeDouble( d_base * 1.750, 0 );		// 3-4ピン間の価格差
	diff_buy_price_order[3] = (int)NormalizeDouble( d_base * 2.125, 0 );		// 4-5ピン間の価格差
	diff_buy_price_order[4] = (int)NormalizeDouble( d_base * 2.500, 0 );		// 5-6ピン間の価格差
	diff_buy_price_order[5] = (int)NormalizeDouble( d_base * 2.875, 0 );		// 6-7ピン間の価格差
	diff_buy_price_order[6] = (int)NormalizeDouble( d_base * 3.250, 0 );		// 7-8ピン間の価格差
	diff_buy_price_order[7] = (int)NormalizeDouble( d_base * 4.250, 0 );		// 8-9ピン間の価格差
	diff_buy_price_order[8] = (int)NormalizeDouble( d_base * 5.250, 0 );		// 9-10ピン間の価格差
	diff_buy_price_order[9] = (int)NormalizeDouble( d_base * 5.250, 0 );		// 10-ピン間の価格差
	
	for ( int i =10; i < MAX_DIFF_PRICE_LIST_NUM; i++ ){
		diff_buy_price_order[i] = (int)NormalizeDouble( d_base * 5.250, 0 );	// 11-ピン間の価格差
	}
	
	d_base = (double)AM_1st_sell_width;
	
	/* 値幅を設定 */
	diff_sell_price_order[0] = (int)NormalizeDouble( d_base * 1.000, 0 );		// 1-2ピン間の価格差
	diff_sell_price_order[1] = (int)NormalizeDouble( d_base * 1.375, 0 );		// 2-3ピン間の価格差
	diff_sell_price_order[2] = (int)NormalizeDouble( d_base * 1.750, 0 );		// 3-4ピン間の価格差
	diff_sell_price_order[3] = (int)NormalizeDouble( d_base * 2.125, 0 );		// 4-5ピン間の価格差
	diff_sell_price_order[4] = (int)NormalizeDouble( d_base * 2.500, 0 );		// 5-6ピン間の価格差
	diff_sell_price_order[5] = (int)NormalizeDouble( d_base * 2.875, 0 );		// 6-7ピン間の価格差
	diff_sell_price_order[6] = (int)NormalizeDouble( d_base * 3.250, 0 );		// 7-8ピン間の価格差
	diff_sell_price_order[7] = (int)NormalizeDouble( d_base * 4.250, 0 );		// 8-9ピン間の価格差
	diff_sell_price_order[8] = (int)NormalizeDouble( d_base * 5.250, 0 );		// 9-10ピン間の価格差
	diff_sell_price_order[9] = (int)NormalizeDouble( d_base * 5.250, 0 );		// 10-ピン間の価格差
	
	for ( int i =10; i < MAX_DIFF_PRICE_LIST_NUM; i++ ){
		diff_sell_price_order[i] = (int)NormalizeDouble( d_base * 5.250, 0 );	// 11-ピン間の価格差
	}
	
#ifdef debug_Configuration
	for ( int i =0; i < MAX_DIFF_PRICE_LIST_NUM; i++ ){
		Print(i,"	",diff_buy_price_order[i]);
	}
	for ( int i =0; i < MAX_DIFF_PRICE_LIST_NUM; i++ ){
		Print(i,"	",diff_sell_price_order[i]);
	}
#endif
	
	return;
}


//**************************************************
// 後で削除する
//**************************************************
/* ロット設定、BaseLotに対する倍率List */
/*
double lot_list[]={
	1,	// 注文1つ目のベースロット(m_base_lot)に対する倍率
	2,	// 注文2つ目のベースロット(m_base_lot)に対する倍率
	3,	// 注文3つ目のベースロット(m_base_lot)に対する倍率
	4,	// 注文4つ目のベースロット(m_base_lot)に対する倍率
	5,	// 注文5つ目のベースロット(m_base_lot)に対する倍率
	6,	// 注文6つ目のベースロット(m_base_lot)に対する倍率
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14,
	15,
	16
};
*/
#define BASE_DIFF_PRICE_TO_ORDER1	(120)		// 追加注文判定用基準変動価格1
#define BASE_DIFF_PRICE_TO_ORDER2	BASE_DIFF_PRICE_TO_ORDER1+BASE_DIFF_PRICE		// 追加注文判定用基準変動価格2



#else
// CONFICRATION_PATERN_****
#endif

#endif