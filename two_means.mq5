#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

ulong trade_ticket = 0;
bool time_passed = true;
datetime time_candle;
double last_close = 0;

uint MEAN_PERIODS = 423;
uint CANDLE_STICK = 60 * 10;
uint STOP = 20;
double VOLUME = 0.1;

int ma_handler_high = 0;
int ma_handler_low = 0;
int ma_1_handler = 0;

double ma_high_array[];
double ma_low_array[];

bool limit_low;
bool limit_high;

int OnInit() {
   ma_handler_high = iMA(_Symbol, _Period, MEAN_PERIODS, 0, MODE_SMA, PRICE_HIGH);
   ma_handler_low = iMA(_Symbol, _Period, MEAN_PERIODS, 0, MODE_SMA, PRICE_LOW);
   return(INIT_SUCCEEDED);
}


void OnTick() {
   CopyBuffer(ma_handler_high, 0, 1, 2, ma_high_array);
   CopyBuffer(ma_handler_low, 0, 1, 2, ma_low_array);

   time_candle = iTime(_Symbol, _Period, 1);
   last_close = iClose(_Symbol, _Period, 1);

   if (time_candle == StringToTime("2022.09.01 04:32")) {
      Print("hola");
   }

   if (time_passed == false) return;
   if (!PositionSelectByTicket(trade_ticket)) trade_ticket = 0;
   if (trade_ticket > 0) {
      if (
         (
            pos_info.PositionType() == POSITION_TYPE_SELL
            && limit_low == true
            && last_close > ma_low_array[1]
            && last_close > ma_high_array[1]
         )
         ||
         (
            pos_info.PositionType() == POSITION_TYPE_BUY
            && limit_high == true
            && last_close < ma_low_array[1]
            && last_close < ma_high_array[1]
         )
      ) {
         trade.PositionClose(trade_ticket);
      }
   }
   if (trade_ticket == 0) {
      if (
         limit_low == true
         && last_close > ma_low_array[1]
         && last_close > ma_high_array[1]
      ) {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);   
         trade.Buy(VOLUME, _Symbol, Ask, ma_low_array[1]);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(CANDLE_STICK);
         limit_low = false;
      }
      if (
         limit_high == true
         && last_close < ma_low_array[1]
         && last_close < ma_high_array[1]
      ) {
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         trade.Sell(VOLUME, _Symbol, Bid, ma_high_array[1]);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(CANDLE_STICK);
         limit_high = false;
      }
   }
   
   if (last_close < ma_low_array[1]) {
      limit_low = true;
   } else if (
      last_close > ma_high_array[1]
   ) {
      limit_high = true;
   }
   /*Comment(
      "limit_low ", limit_low, "\n",
      "limit_high ", limit_high, "\n",
      "ma_low_array[1] ", ma_low_array[1], "\n",
      "ma_high_array[1] ", ma_high_array[1], "\n"
   );*/
}

void OnTimer() {
   time_passed = true;
}
  