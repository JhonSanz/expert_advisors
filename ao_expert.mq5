#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

int ao_handler = 0;
double ao_array[];
double ao_array_trade[];
double STOP_MULTIPLIER = 0.5;

int atr_14_handler = 0;
double atr_14_array[];

ulong trade_ticket = 0;
bool time_passed = true;
datetime time_candle;
uint state = 9;

uint GREEN = 1;
uint RED = 0;
bool can_trade = true;
double diff = 0;
uint SECONDS = 300;

int OnInit() {
   ao_handler = iCustom(_Symbol, _Period, "../Indicators/Examples/Awesome_Oscillator_2");
   atr_14_handler = iATR(_Symbol, _Period, 14);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   CopyBuffer(ao_handler, 0, 1, 2, ao_array);
   time_candle = iTime(_Symbol, _Period, 1);
   if (time_passed == false) return;
   if (!PositionSelectByTicket(trade_ticket)) trade_ticket = 0;

   if (trade_ticket > 0) {
      if (
         pos_info.PositionType() == POSITION_TYPE_SELL
         && ao_array[1] > ao_array[0]
         && state == RED
      ) {
         state = GREEN;
         trade.PositionClose(trade_ticket); 
      } else if (
         pos_info.PositionType() == POSITION_TYPE_BUY
         && ao_array[1] < ao_array[0]
         && state == GREEN
      ) {
         state = RED;
         trade.PositionClose(trade_ticket); 
      }
   } else {
      double Ask_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      double Bid_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      diff = Ask_op - Bid_op;

      CopyBuffer(ao_handler, 0, 1, 3, ao_array_trade);
      if (
         (
            ao_array_trade[1] <= 0
            && ao_array_trade[0] > 0
         )
         ||
         (
            ao_array_trade[1] >= 0
            && ao_array_trade[0] < 0
         )
         ||
         (
            (
               ao_array_trade[0] < 0
               && ao_array_trade[1] < 0
               && ao_array_trade[2] < 0 
            ) &&
            (
               (
                  ao_array_trade[2] > ao_array_trade[1]
                  && ao_array_trade[1] < ao_array_trade[0]
               ) ||
               (
                  ao_array_trade[2] < ao_array_trade[1]
                  && ao_array_trade[1] > ao_array_trade[0]
               )
            )
         )
         ||
         (
            (
               ao_array_trade[0] > 0
               && ao_array_trade[1] > 0
               && ao_array_trade[2] > 0 
            ) &&
            (
               (
                  ao_array_trade[2] > ao_array_trade[1]
                  && ao_array_trade[1] < ao_array_trade[0]
               ) ||
               (
                  ao_array_trade[2] < ao_array_trade[1]
                  && ao_array_trade[1] > ao_array_trade[0]
               )
            )
         )
      ) {
         if(diff > 1) {
            can_trade = false;
         } else {
            can_trade = true;
         }
      }

      if (can_trade == false) return;
      CopyBuffer(atr_14_handler, 0, 1, 1, atr_14_array);
      if (
         (
            ao_array[1] <= 0
            && ao_array[0] > 0
         )
         ||
         (
            ao_array[0] < 0
            && ao_array[1] < 0
            && ao_array[1] < ao_array[0]
            && state == GREEN
         )
      ) {
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         trade.Sell(0.1, _Symbol, Bid, Bid + (atr_14_array[0] * STOP_MULTIPLIER));
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(SECONDS);
         if (PositionSelectByTicket(trade_ticket)) {
            state = RED;
         }
         can_trade = false;
      } else if (
         (
            ao_array[1] >= 0
            && ao_array[0] < 0
         )
         ||
         (
            ao_array[0] > 0
            && ao_array[1] > 0
            && ao_array[1] > ao_array[0]
            && state == RED
         )
      ) {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);   
         trade.Buy(0.1, _Symbol, Ask, Ask - (atr_14_array[0] * STOP_MULTIPLIER));
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(SECONDS);
         if (PositionSelectByTicket(trade_ticket)) {
            state = GREEN;
         }
         can_trade = false;
      }
   }
}

void OnTimer() {
   time_passed = true;
}
