
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
 
CTrade trade;
CPositionInfo pos_info;

bool time_passed = true;
ulong trade_ticket = 0;
bool first_position = true;
double initial_price = 0.0;
double brick_size = 0.0;
uint BRICK_BOX_VALUE = 2000;
double VOLUME = 0.1;
double point = 0.0;
double diff = 0.0;
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
   diff = ask - bid;

   if (diff >= SPREAD) return;
   if (first_position) {
        if((bid - initial_price) >= brick_size) {
            trade.Buy(VOLUME, _Symbol, ask, bid - brick_size, bid + brick_size);
            last_sl = bid - brick_size;
            last_tp = bid + brick_size;
            last_type = POSITION_TYPE_BUY;
        } else if ((initial_price - bid) >= brick_size) {
            trade.Sell(VOLUME, _Symbol, bid, bid + brick_size, bid - brick_size);
            last_sl = bid + brick_size;
            last_tp = bid - brick_size;
            last_type = POSITION_TYPE_SELL;
        }
        if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {
            first_position = false;
        }
   } else {
      datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
      HistorySelect(today, TimeCurrent());
      uint history_total = HistoryOrdersTotal();
      // ulong result = HistorySelectByPosition(history_total);
      ulong ticket = HistoryOrderGetTicket(history_total);
      
      Comment(
         "total history: ", history_total, "\n",
         "ticket: ", ticket, "\n"
      );
 
      if (
            HistoryOrderGetInteger(ticket, ORDER_TYPE) == ORDER_TYPE_BUY &&
            HistoryOrderGetInteger(ticket, ORDER_REASON) == ORDER_REASON_TP
      ) {
         trade.Buy(VOLUME, _Symbol, ask, bid - brick_size, bid + brick_size);
         Print("ticket ", ticket);
         Print(HistoryOrderGetInteger(ticket, ORDER_REASON));
         Print("ORDER_REASON_SL: ", ORDER_REASON_SL);
         Print("ORDER_REASON_TP: ", ORDER_REASON_TP);
      } else if (
            HistoryOrderGetInteger(ticket, ORDER_TYPE) == ORDER_TYPE_BUY &&
            HistoryOrderGetInteger(ticket, ORDER_REASON) == ORDER_REASON_SL
      ) {
         trade.Sell(VOLUME, _Symbol, bid, bid + brick_size, bid - brick_size);
         Print("ticket ", ticket);
         Print(HistoryOrderGetInteger(ticket, ORDER_REASON));
         Print("ORDER_REASON_SL: ", ORDER_REASON_SL);
         Print("ORDER_REASON_TP: ", ORDER_REASON_TP);
      } else if (
            HistoryOrderGetInteger(ticket, ORDER_TYPE) == ORDER_TYPE_SELL &&
            HistoryOrderGetInteger(ticket, ORDER_REASON) == ORDER_REASON_TP
      ) {
         trade.Sell(VOLUME, _Symbol, bid, bid + brick_size, bid - brick_size);
         Print("ticket ", ticket);
         Print(HistoryOrderGetInteger(ticket, ORDER_REASON));
         Print("ORDER_REASON_SL: ", ORDER_REASON_SL);
         Print("ORDER_REASON_TP: ", ORDER_REASON_TP);
      } else if (
            HistoryOrderGetInteger(ticket, ORDER_TYPE) == ORDER_TYPE_SELL &&
            HistoryOrderGetInteger(ticket, ORDER_REASON) == ORDER_REASON_SL
      ) {
         trade.Buy(VOLUME, _Symbol, ask, bid - brick_size, bid + brick_size);
         Print("ticket ", ticket);
         Print(HistoryOrderGetInteger(ticket, ORDER_REASON));
         Print("ORDER_REASON_SL: ", ORDER_REASON_SL);
         Print("ORDER_REASON_TP: ", ORDER_REASON_TP);
      }
      if (trade.ResultRetcode() != TRADE_RETCODE_DONE) {
         first_position = true;
         initial_price = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      }
   }
}

void OnTimer() {
   time_passed = true;
}
