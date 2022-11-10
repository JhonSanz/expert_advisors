#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

uint BUY_TRANSACTION = 1;
uint SELL_TRANSACTION = 0;

ulong trade_ticket = 0;
bool time_passed = true;
datetime time_candle;
double candle_close;

int ma_200_handler = 0;
int macd_handler = 0;

double ma_200_array[];
double macd_signal_array[];
double macd_main_array[];

int OnInit() {
   macd_handler = iMACD(_Symbol, _Period, 12, 26, 5, PRICE_CLOSE);
   ma_200_handler = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}

double GetStopLoss(uint type_transaction, double current_price) {
   uint i = 3;
   double prev_candle = iLow(_Symbol, _Period, 2);
   double stop_candle = iLow(_Symbol, _Period, 3);
   if(type_transaction == BUY_TRANSACTION) {
      while(true) {
         if(
            prev_candle < current_price
            && stop_candle > prev_candle
         ) {
            return current_price - (current_price - prev_candle); 
         } else {
            prev_candle = stop_candle;
            stop_candle = iLow(_Symbol, _Period, i);
            i += 1;
         }
      }
   } else if (type_transaction == SELL_TRANSACTION) {
      while(true) {
         if(
            prev_candle > current_price
            && stop_candle < prev_candle
         ) {
            return current_price + (prev_candle - current_price); 
         } else {
            prev_candle = stop_candle;
            stop_candle = iLow(_Symbol, _Period, i);
            i += 1;
         }
      }
   }
   return 0;
}

double GetProffit(uint type_transaction, double stop, double current_price) {
   double difference = current_price - stop;
   if(type_transaction == BUY_TRANSACTION)
      return (current_price + (difference * 1.5));
   if(type_transaction == SELL_TRANSACTION)
      return (current_price - (difference * 1.5));
   return 0;
}

void OnTick() {
   CopyBuffer(ma_200_handler, 0, 1, 1, ma_200_array);
   CopyBuffer(macd_handler, 0, 1, 2, macd_main_array);
   CopyBuffer(macd_handler, 1, 1, 2, macd_signal_array);

   candle_close = iClose(_Symbol, _Period, 1);
   time_candle = iTime(_Symbol, _Period, 1);

   if (time_passed == false) return;
   if (!PositionSelectByTicket(trade_ticket)) trade_ticket = 0;
   if (trade_ticket > 0) return;
   if (ma_200_array[0] == 0) return;

   if (
      ma_200_array[0] < candle_close 
      && macd_main_array[0] < macd_signal_array[0]
      && macd_main_array[1] > macd_signal_array[1]
   ) {
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      double stop_loss = GetStopLoss(BUY_TRANSACTION, Ask);
      double take_profit = GetProffit(BUY_TRANSACTION, stop_loss, Ask);
      trade.Buy(1, _Symbol, Ask, stop_loss, take_profit);
      trade_ticket = trade.ResultOrder();
      time_passed = false;
      EventSetTimer(1800);
   } else if (
      ma_200_array[0] > candle_close
      && macd_main_array[0] > macd_signal_array[0]
      && macd_main_array[1] < macd_signal_array[1]
   ) {
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      double stop_loss = GetStopLoss(SELL_TRANSACTION, Bid);
      double take_profit = GetProffit(SELL_TRANSACTION, stop_loss, Bid);
      trade.Sell(1, _Symbol, Bid, stop_loss, take_profit);
      trade_ticket = trade.ResultOrder();
      time_passed = false;
      EventSetTimer(1800);
   }

}

void OnTimer() {
   time_passed = true;
}
