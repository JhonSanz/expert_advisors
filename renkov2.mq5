#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
 
CTrade trade;
CPositionInfo pos_info;

bool time_passed = true;
ulong trade_ticket = 0;
bool first_position = true;
double initial_price = 0.0;
double brick_size = 0.0;
uint BRICK_BOX_VALUE = 200;
double VOLUME = 0.1;
double point = 0.0;
double spread = 0.0;
uint SPREAD = 100;

uint last_type;
double last_sl;
double last_tp;

int OnInit() {
   point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   brick_size = BRICK_BOX_VALUE * point;
   initial_price = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   spread = ask - bid;

   if (spread <= SPREAD * point) {
      if (first_position) {
           if(bid >= (initial_price + brick_size - spread)) {
               trade.Buy(VOLUME, _Symbol, 0, ask - brick_size, bid + brick_size, (string)spread);
               last_sl = ask - brick_size;
               last_tp = bid + brick_size;
               last_type = POSITION_TYPE_BUY;
           } else if (ask <= (initial_price - brick_size + spread)) {
               trade.Sell(VOLUME, _Symbol, 0, bid + brick_size, ask - brick_size, (string)spread);
               last_sl = bid + brick_size;
               last_tp = ask - brick_size;
               last_type = POSITION_TYPE_SELL;
           }
           if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {
               first_position = false;
           }
      } else {
         if (last_type == POSITION_TYPE_BUY && bid >= last_tp) {
            trade.Buy(VOLUME, _Symbol, 0, ask - brick_size, bid + brick_size);
            last_sl = ask - brick_size;
            last_tp = bid + brick_size;
            last_type = POSITION_TYPE_BUY;
         } else if (last_type == POSITION_TYPE_BUY && bid <= last_sl) {
            trade.Sell(VOLUME, _Symbol, 0, bid + brick_size, ask - brick_size);
            last_sl = bid + brick_size;
            last_tp = ask - brick_size;
            last_type = POSITION_TYPE_SELL;
         } else if (last_type == POSITION_TYPE_SELL && ask <= last_tp) {
            trade.Sell(VOLUME, _Symbol, 0, bid + brick_size, ask - brick_size);
            last_sl = bid + brick_size;
            last_tp = ask - brick_size;
            last_type = POSITION_TYPE_SELL;
         } else if (last_type == POSITION_TYPE_SELL && ask >= last_sl) {
            trade.Buy(VOLUME, _Symbol, 0, ask - brick_size, bid + brick_size);
            last_sl = ask - brick_size;
            last_tp = bid + brick_size;
            last_type = POSITION_TYPE_BUY;
         }
         if (trade.ResultRetcode() != TRADE_RETCODE_DONE) {
            first_position = true;
            initial_price = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         }
      }
   }
}

void OnTimer() {
   time_passed = true;
}