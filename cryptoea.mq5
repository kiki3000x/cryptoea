#include "Handler.mqh"
//**************************************************
// define
//**************************************************
//**************************************************
//data for display
//**************************************************
#property copyright 	"Copyright 2021, Team T&T."
#property link			"https://www.mql5.com"
#property version		EA_VERSION
#property description	"◆◆◆注意◆◆◆\n本EAは、価格幅20000USD～80000USDのBTC-USDトレード相場に適用させたナンピンマーチンを基本とし、さらにオリジナルな攻めと守りの機能を追加したクリプト専用のオリジナルEAです。\nあくまでも趣味の範囲のものであるため、使用に関する一切の保証などはありません。\nその旨ご承知おきください。"
#property icon			"logo.ico"

CHandler* C_Handler = CHandler::GetHandler();
CLogger*  C_logger = CLogger::GetLog();
//+----------------------------------------------------------- -------+
//| Expert initialization function                                   |
//+------------------6------------------------------------------------+
int OnInit(){
	C_Handler.OnInit();
	return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
	C_Handler.OnDeinit(reason);
	//--- destroy timer
	EventKillTimer();
 }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
	C_Handler.OnTick();
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(){
	C_Handler.OnTimer();
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                                   |
//+------------------------------------------------------------------+
void OnTradeTransaction(
	const MqlTradeTransaction&    trans,
	const MqlTradeRequest&      request,
	const MqlTradeResult&       result
){
	C_Handler.OnTradeTransaction(trans,request,result);
}

