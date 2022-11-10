#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

ulong trade_ticket = 0;
bool time_passed = true;
datetime time_candle;
double last_close = 0;
double last_high = 0;
double last_low = 0;
double last_open = 0;

uint MEAN_PERIODS = 380;
uint CANDLE_STICK = 60 * 30;
double VOLUME = 0.1;

int ma_handler = 0;
double ma_array[];

int OnInit() {
   ma_handler = iMA(_Symbol, _Period, MEAN_PERIODS, 0, MODE_SMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}


void OnTick() {
   CopyBuffer(ma_handler, 0, 1, 2, ma_array);
   time_candle = iTime(_Symbol, _Period, 1);
   last_close = iClose(_Symbol, _Period, 1);
   last_open = iOpen(_Symbol, _Period, 1);
   last_high = iHigh(_Symbol, _Period, 1);
   last_low = iLow(_Symbol, _Period, 1);

   if (time_passed == false) return;
   if (!pos_info.SelectByTicket(trade_ticket)) trade_ticket = 0;
   if (trade_ticket > 0) {
      if (
         (
            (last_close - pos_info.PriceOpen()) > 0 &&
            pos_info.PositionType() == POSITION_TYPE_BUY
         )
         ||
         (
            (pos_info.PriceOpen() - last_close) > 0 &&
            pos_info.PositionType() == POSITION_TYPE_SELL
         )
      ) {
         trade.PositionClose(trade_ticket);
      }
   }
   if (trade_ticket == 0) {
      if (
         last_low > ma_array[1] &&
         (last_close - last_open) > 0
      ) {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);   
         trade.Buy(VOLUME, _Symbol, Ask, last_low);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(CANDLE_STICK);
      }
      if (
         last_high < ma_array[1] &&
         (last_close - last_open) < 0
      ) {
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         trade.Sell(VOLUME, _Symbol, Bid, last_high);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(CANDLE_STICK);
      }
   }
}

void OnTimer() {
   time_passed = true;
}
  