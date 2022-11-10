#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

ulong trade_ticket = 0;
bool time_passed = true;
datetime time_candle;

int ma_500_handler = 0;
int ma_1_handler = 0;
int ma_20_handler = 0;
double ma_500_array[];
double ma_1_array[];
double ma_20_array[];

int OnInit() {
   ma_1_handler = iMA(_Symbol, _Period, 30, 0, MODE_EMA, PRICE_CLOSE);
   ma_500_handler = iMA(_Symbol, _Period, 1000, 0, MODE_EMA, PRICE_CLOSE);
   ma_20_handler = iMA(_Symbol, _Period, 10, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}


void OnTick() {
   CopyBuffer(ma_1_handler, 0, 1, 2, ma_1_array);
   CopyBuffer(ma_500_handler, 0, 1, 2, ma_500_array);
   CopyBuffer(ma_20_handler, 0, 1, 1, ma_20_array);

   time_candle = iTime(_Symbol, _Period, 1);

   if (time_passed == false) return;
   if (!PositionSelectByTicket(trade_ticket)) trade_ticket = 0;
   if (trade_ticket > 0) {
      if (
         (
            pos_info.PositionType() == POSITION_TYPE_SELL
            && ma_1_array[0] < ma_500_array[0]
            && ma_1_array[1] > ma_500_array[1]

         )
         
         ||
         (
            pos_info.PositionType() == POSITION_TYPE_BUY
            && ma_1_array[0] > ma_500_array[0]
            && ma_1_array[1] < ma_500_array[1]
         )
      ) {
         trade.PositionClose(trade_ticket);
      }
   } else {
      if (
         ma_1_array[0] < ma_500_array[0]
         && ma_1_array[1] > ma_500_array[1]
      ) {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);   
         trade.Buy(1, _Symbol, Ask, ma_20_array[0]);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(300);
      } else if (
         ma_1_array[0] > ma_500_array[0]
         && ma_1_array[1] < ma_500_array[1]
      ) {
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         trade.Sell(1, _Symbol, Bid, ma_20_array[0]);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(300);
      }
   }
}

void OnTimer() {
   time_passed = true;
}
  