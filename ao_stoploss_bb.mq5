#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

uint BUY = 0;
uint SELL = 1;

ulong ticket_buy = 0;
ulong ticket_sell = 0;

bool time_passed = true;
datetime time_candle;

int ma_1_handler = 0;
int bol_bands_handler = 0;

double ma_1_array[];
double bol_bands_base[];
double bol_bands_upper[];
double bol_bands_lower[];

double profit = 0;
double diff = 0;

// SPREAD, SI ES 1 SON 100 PUNTOS
double SPREAD = 1;
// SEGUNDOS DEPENDIENDO DEL MARCO TEMPORAL EJ: 1800 SEGUNDOS SON VELAS DE 30MIN EN SEGUNDOS
uint TIME_FRAME = 1800;
// VOLUMEN DE LA TRANSACCION
double VOLUME = 0.1;
uint BOLLINGER_PERIODS = 70;
double STANDARD_DEVIATIONS = 0.7;


int OnInit() {
   ma_1_handler = iMA(_Symbol, _Period, 1, 0, MODE_EMA, PRICE_CLOSE);
   bol_bands_handler = iBands(_Symbol, _Period, BOLLINGER_PERIODS, 0, STANDARD_DEVIATIONS, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
}


uint DIVISOR = 2;
double divideCandleByTree(double close, double open) {
   if (close > open) {
      return (close - open) / DIVISOR;
   }
   return (open - close) / DIVISOR;
}

double getStopLoss(
   uint type, double close, double open,
   double bandUpper, double bandLower
) {
   if (type == BUY) {
         if(close > bandUpper) {
            return close - divideCandleByTree(close, open);
         }
         return bandLower;
   }
   if(close < bandLower) {
      return close + divideCandleByTree(close, open);
   }
   return bandUpper;
}

void OnTick() {
   CopyBuffer(ma_1_handler, 0, 1, 2, ma_1_array);
   CopyBuffer(bol_bands_handler, 0, 1, 2, bol_bands_base);
   CopyBuffer(bol_bands_handler, 1, 1, 1, bol_bands_upper);
   CopyBuffer(bol_bands_handler, 2, 1, 1, bol_bands_lower);

   time_candle = iTime(_Symbol, _Period, 1);

   double Ask_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   diff = Ask_op - Bid_op;

   if (time_passed == false) return;

   if(!pos_info.SelectByTicket(ticket_sell)) ticket_sell = 0;
   if(
      ma_1_array[0] < bol_bands_base[0]
      && ma_1_array[1] > bol_bands_base[1]
      && ticket_sell > 0
      && pos_info.PriceOpen() > ma_1_array[1]
      && pos_info.PositionType() == POSITION_TYPE_SELL
   ) {
      trade.PositionClose(ticket_sell);
      if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {
         ticket_sell = 0;
      }
   } 
   
   if(!pos_info.SelectByTicket(ticket_buy)) ticket_buy = 0;
   if(
      ma_1_array[0] > bol_bands_base[0]
      && ma_1_array[1] < bol_bands_base[1]
      && ticket_buy > 0
      && pos_info.PriceOpen() < ma_1_array[1]
      && pos_info.PositionType() == POSITION_TYPE_BUY
   ) {
      trade.PositionClose(ticket_buy);
      if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {
         ticket_buy = 0;
      }
   }

   if (
      ma_1_array[0] < bol_bands_base[0]
      && ma_1_array[1] > bol_bands_base[1]
      && diff <= SPREAD
      && ticket_buy == 0
   ) {
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      trade.Buy(
         VOLUME, _Symbol, Ask,
         getStopLoss(
            BUY, ma_1_array[1], iOpen(_Symbol, _Period, 1),
            bol_bands_upper[0], bol_bands_lower[0]
         )
      );     
      if (trade.ResultRetcode() == TRADE_RETCODE_INVALID_STOPS) {
         trade.Buy(VOLUME, _Symbol, Ask, bol_bands_lower[0]);
      }
      ticket_buy = trade.ResultOrder();
      time_passed = false;
      EventSetTimer(TIME_FRAME);
   } else if (
      ma_1_array[0] > bol_bands_base[0]
      && ma_1_array[1] < bol_bands_base[1]
      && diff <= SPREAD
      && ticket_sell == 0
   ) {
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      trade.Sell(
         VOLUME, _Symbol, Bid,
         getStopLoss(
            SELL, ma_1_array[1], iOpen(_Symbol, _Period, 1),
            bol_bands_upper[0], bol_bands_lower[0]
         )
      );
      if (trade.ResultRetcode() == TRADE_RETCODE_INVALID_STOPS) {
         trade.Sell(VOLUME, _Symbol, Bid, bol_bands_upper[0]);
      }
      ticket_sell = trade.ResultOrder();
      time_passed = false;
      EventSetTimer(TIME_FRAME);
   }

}

void OnTimer() {
   time_passed = true;
}
  