//+------------------------------------------------------------------+
//|                                              candle_strategy.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
 #include <Arrays\List.mqh>
 
CTrade trade;
CPositionInfo pos_info;

uint TIME_FRAME = 1800;
double VOLUME = 0.1;
double SPREAD = 1;

bool time_passed = true;
double close;
double open;
double high;
double low;
// int time_handler = 0;
// double time_array[];

CList positions;

ulong ticket_buy = 0;
ulong ticket_sell = 0;


int OnInit() {
   // time_handler = iCustom(_Symbol, _Period, "../Indicators/Examples/time");
   return(INIT_SUCCEEDED);
}

string printArray(CList &my_array) {
   string result = "";
   int len = my_array.Total();
   for (int i = 0; i <= len; i++) {
      StringConcatenate(result, (string)my_array.At(i), "-");
   }
   return result;
}

void OnTick() {
   close = iClose(_Symbol, _Period, 1);
   open = iOpen(_Symbol, _Period, 1);
   high = iHigh(_Symbol, _Period, 1);
   low = iLow(_Symbol, _Period, 1);
   // CopyBuffer(time_handler, 0, 1, 0, time_array);
   
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

   double diff = Ask - Bid;
   
   int totalPositions = positions.Total();
   for (int i = 0; i < totalPositions; i++) {
      CObject *ticket = positions.GetNodeAtIndex(i);
      // pos_info.SelectByTicket(ticket);
      /*if (
         pos_info.PositionType() == POSITION_TYPE_BUY
         && pos_info.PriceOpen() < close
      ) {
         trade.PositionClose(ticket);
         if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {
            positions.Delete(i);
         }
      } */
      /*Print("Position ", i, " element ", positions.GetNodeAtIndex(i), " ticket ", ticket);
      if(
         pos_info.PositionType() == POSITION_TYPE_SELL
         && pos_info.PriceOpen() > (close + diff)
      ) {
         trade.PositionClose(ticket);
         Print("to delete: ", positions.GetNodeAtIndex(i));
         positions.Delete(i);
         Print("delete elements", );
      }*/
   }

   if (time_passed) {
      if (close > open) { // es vela verde
         /*trade.Buy(VOLUME, _Symbol, Ask, low);
         if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {
            ticket_buy = trade.ResultOrder();
            positions.Add(ticket_buy);
         }
         time_passed = false;
         EventSetTimer(TIME_FRAME);*/
      } 
      if (close < open) { // es vela roja
         trade.Sell(VOLUME, _Symbol, Bid, high);
         ticket_sell = trade.ResultOrder();
         positions.Add(1);
         time_passed = false;
         EventSetTimer(TIME_FRAME);
      }
   }
}

void OnTimer() {
   time_passed = true;
}
  