#include "CSV.mqh"
#include "Logger.mqh"
//**************************************************
// define
//**************************************************
#define EA_VERSION		"1.00"
//**************************************************
// アプリ表示データ
//**************************************************
#property copyright 	"Copyright 2021, Team T&T."
#property link			"https://www.mql5.com"
#property version		EA_VERSION

input int minites = 60;
input int hours = 24;

CCSV*  C_CSV = CCSV::GetCSV();
CLogger* C_logger = CLogger::GetLog();
//-----------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
	int bar_num_m1 = Bars(Symbol(),PERIOD_M1);
	int bar_num_h1 = Bars(Symbol(),PERIOD_H1);
	MqlDateTime stm;
	MqlDateTime htm;
	MqlDateTime ltm;
	C_logger.output_log_to_file(StringFormat("OutputHighLowData Oninit() bar_num_m1 = %d bar_num_h1 = %d"
	                                         ,bar_num_m1,bar_num_h1));

	//分単位指定値に対する処理(10万分がデータ限界、1か月)
	int roop = bar_num_m1 / minites;
	C_logger.output_log_to_file(StringFormat("OutputHighLowData Oninit() roop = %d　minites = %d",roop,minites));
	C_CSV.output_csv_to_file(StringFormat("■■■■■■■■%d分単位のデータ■■■■■■■■",minites),StringFormat("%dmin",minites));
	C_CSV.output_csv_to_file("開始時間,High時間,High値,Low時間,Low値");
	for( int i = 0; i < roop; i++){
		int val_index=0;
		double val_high=0;
		double val_low=0;
		datetime high_date_time;
		datetime low_date_time;
		datetime start_date_time;

		//指定期間の最高値取得と時刻取得
		val_index=iHighest(Symbol(), PERIOD_M1, MODE_HIGH, minites, i*minites);
		if(val_index!=-1){
     		val_high = iHigh(Symbol(),PERIOD_M1,val_index);
			high_date_time = iTime(Symbol(), PERIOD_M1, val_index);
			//C_logger.output_log_to_file(StringFormat("OutputHighLowData Oninit() %s val_index = %d val_high = %f"
			//                                         ,TimeToString(high_date_time),val_index,val_high));
		}
  		else{
     		C_logger.output_log_to_file(StringFormat("iHighest() call error. Error code=%d",GetLastError()));
		}

		//指定期間の最安値取得と時刻取得
		val_index=iLowest(Symbol(), PERIOD_M1, MODE_LOW, minites, i*minites);
		if(val_index!=-1){
     		val_low = iLow(Symbol(),PERIOD_M1,val_index);;
			low_date_time = iTime(Symbol(), PERIOD_M1, val_index);
			//C_logger.output_log_to_file(StringFormat("OutputHighLowData Oninit() %s val_index = %d val_low = %f"
			//                                         ,TimeToString(low_date_time),val_index,val_low));
		}
		else{
     		C_logger.output_log_to_file(StringFormat("iLowest() call error. Error code=%d",GetLastError()));
		}
		
		//指定期間の開始日時取得
		start_date_time = iTime(Symbol(), PERIOD_M1, i*minites);
		//時間成形
		TimeToStruct(start_date_time,stm);
		TimeToStruct(high_date_time,htm);
		TimeToStruct(low_date_time,ltm);

		//CSV出力
		C_CSV.output_csv_to_file(StringFormat("%s/%s/%s %s:%s,%s/%s/%s %s:%s,%f,%s/%s/%s %s:%s,%f"
		                                      ,(string)stm.year,(string)stm.mon,(string)stm.day,(string)stm.hour,(string)stm.min
		                                      ,(string)htm.year,(string)htm.mon,(string)htm.day,(string)htm.hour,(string)htm.min
											  ,val_high
											  ,(string)ltm.year,(string)ltm.mon,(string)ltm.day,(string)ltm.hour,(string)ltm.min
											  ,val_low));
	}
	//ファイル名変更のためいったん閉じる
	C_CSV.close_csv_file();

	//時間単位指定値に対する処理(10万分がデータ限界、1か月)
	roop = bar_num_h1 / hours;
	C_logger.output_log_to_file(StringFormat("OutputHighLowData Oninit() roop = %hours = %d",roop,hours));
	C_CSV.output_csv_to_file(StringFormat("■■■■■■■■%d時間単位のデータ■■■■■■■■",hours),StringFormat("%dhour",hours));
	C_CSV.output_csv_to_file("開始時間,High時間,High値,Low時間,Low値");
	
	for( int i = 0; i < roop; i++){
		int val_index=0;
		double val_high=0;
		double val_low=0;
		datetime high_date_time;
		datetime low_date_time;
		datetime start_date_time;

		//指定期間の最高値取得と時刻取得
		val_index=iHighest(Symbol(),PERIOD_H1, MODE_HIGH, hours, i*hours);
		if(val_index!=-1){
     		val_high = iHigh(Symbol(),PERIOD_H1,val_index);
			high_date_time = iTime(Symbol(), PERIOD_H1, val_index);
			//C_logger.output_log_to_file(StringFormat("OutputHighLowData Oninit() %s val_index = %d val_high = %f"
			//                                         ,TimeToString(high_date_time),val_index,val_high));
		}
  		else{
     		C_logger.output_log_to_file(StringFormat("iHighest() call error. Error code=%d",GetLastError()));
		}

		//指定期間の最安値取得と時刻取得
		val_index=iLowest(Symbol(), PERIOD_H1, MODE_LOW, hours, i*hours);
		if(val_index!=-1){
     		val_low = iLow(Symbol(),PERIOD_H1,val_index);;
			low_date_time = iTime(Symbol(), PERIOD_H1, val_index);
			//C_logger.output_log_to_file(StringFormat("OutputHighLowData Oninit() %s val_index = %d val_low = %f"
			//                                         ,TimeToString(low_date_time),val_index,val_low));
		}
		else{
     		C_logger.output_log_to_file(StringFormat("iLowest() call error. Error code=%d",GetLastError()));
		}

		//指定期間の開始日時取得
		start_date_time = iTime(Symbol(), PERIOD_H1, i*hours);
		//時間成形
		TimeToStruct(start_date_time,stm);
		TimeToStruct(high_date_time,htm);
		TimeToStruct(low_date_time,ltm);

		//CSV出力
		C_CSV.output_csv_to_file(StringFormat("%s/%s/%s %s:%s,%s/%s/%s %s:%s,%f,%s/%s/%s %s:%s,%f"
		                                      ,(string)stm.year,(string)stm.mon,(string)stm.day,(string)stm.hour,(string)stm.min
		                                      ,(string)htm.year,(string)htm.mon,(string)htm.day,(string)htm.hour,(string)htm.min
											  ,val_high
											  ,(string)ltm.year,(string)ltm.mon,(string)ltm.day,(string)ltm.hour,(string)ltm.min
											  ,val_low));
	}

	//終了処理
	C_CSV.close_csv_file();
	Alert("Collecting data Fini na!! sabai na!!");
	ExpertRemove();
	return(INIT_SUCCEEDED);
}

