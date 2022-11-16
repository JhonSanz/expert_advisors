#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

ulong trade_ticket = 0;
bool time_passed = true;
datetime time_candle;
double last_close = 0;
double last_low = 0;
double last_high = 0;

uint MEAN_PERIODS = 715;
uint CANDLE_STICK = 60 * 10;
double VOLUME = 0.1;
double LIMIT_STOP = 500; // puntos

int ma_handler_high = 0;
int ma_handler_low = 0;
int ma_1_handler = 0;

double ma_high_array[];
double ma_low_array[];

bool limit_low;
bool limit_high;
double diff = 0;
double SPREAD = 10;
double point = 0.0;

int OnInit() {
   point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   // SPREAD = SPREAD * point;
   LIMIT_STOP = LIMIT_STOP * point;
   ma_handler_high = iMA(_Symbol, _Period, MEAN_PERIODS, 0, MODE_SMA, PRICE_HIGH);
   ma_handler_low = iMA(_Symbol, _Period, MEAN_PERIODS, 0, MODE_SMA, PRICE_LOW);
   return(INIT_SUCCEEDED);
}


void OnTick() {
   CopyBuffer(ma_handler_high, 0, 1, 2, ma_high_array);
   CopyBuffer(ma_handler_low, 0, 1, 2, ma_low_array);

   time_candle = iTime(_Symbol, _Period, 1);
   last_close = iClose(_Symbol, _Period, 1);
   last_low = iLow(_Symbol, _Period, 1);
   last_high = iHigh(_Symbol, _Period, 1);

   double Ask_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   diff = Ask_op - Bid_op;

   MqlDateTime rightNow;
   TimeCurrent(rightNow);
   TimeToStruct(TimeCurrent(),rightNow);
   if (!(rightNow.hour > 2 && rightNow.hour < 22)) return;

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
         && diff <= SPREAD
         && last_low > ma_low_array[1]
         && last_low > ma_high_array[1]
      ) {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
         double insurance = 0.0;
         /*if (Ask -  ma_low_array[1] > LIMIT_STOP) {
            insurance = Ask - LIMIT_STOP;
         } else {
            insurance = ma_low_array[1];
         }*/
         insurance = Ask - LIMIT_STOP;
         trade.Buy(VOLUME, _Symbol, Ask, insurance);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(CANDLE_STICK);
         limit_low = false;
      }
      if (
         limit_high == true
         && diff <= SPREAD
         && last_high < ma_low_array[1]
         && last_high < ma_high_array[1]
      ) {
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         double insurance = 0.0;
         /*if (ma_high_array[1] - Bid > LIMIT_STOP) {
            insurance = Bid + LIMIT_STOP;
         } else {
            insurance = ma_high_array[1];
         }*/
         insurance = Bid + LIMIT_STOP;
         trade.Sell(VOLUME, _Symbol, Bid, insurance);
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
  