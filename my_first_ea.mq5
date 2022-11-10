#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos_info;

int ma_265_handler = 0;
int ma_11_handler = 0;
int rsi_2_handler = 0;
int atr_14_handler = 0;
int ao_handler = 0;

ulong trade_ticket = 0;
bool time_passed = true;

double ma_265_array[];
double ma_11_array[];
double rsi_2_array[];
double ma_11_close_pos[];
double atr_14_array[];
double ao_array[];

double stop = 0;

double candle_close;
double prev_close;
datetime time_candle;


double current_open;
double prev_open;

bool done = false;

int OnInit() {
   ma_265_handler = iMA(_Symbol, _Period, 90, 0, MODE_SMA, PRICE_CLOSE);
   ma_11_handler = iMA(_Symbol, _Period, 11, 0, MODE_SMA, PRICE_CLOSE);
   rsi_2_handler = iRSI(_Symbol, _Period, 2, PRICE_CLOSE);
   atr_14_handler = iATR(_Symbol, _Period, 14);
   // ao_handler = iAO(_Symbol, _Period);
   // ao_handler = iCustom(_Symbol, _Period, "../Indicators/Examples/Awesome_Oscillator_2");
   
   return(INIT_SUCCEEDED);
}

void OnTick() {
   CopyBuffer(ma_265_handler, 0, 1, 1, ma_265_array);
   CopyBuffer(ma_11_handler, 0, 1, 1, ma_11_array);
   CopyBuffer(rsi_2_handler, 0, 1, 2, rsi_2_array);
   // CopyBuffer(ao_handler, 0, 1, 1, ao_array);
   
   candle_close = iClose(_Symbol, _Period, 1);
   time_candle = iTime(_Symbol, _Period, 1);
  
   if (time_passed == false) return;
   if (!PositionSelectByTicket(trade_ticket)) trade_ticket = 0;
   if (trade_ticket > 0) {
      CopyBuffer(ma_11_handler, 0, 1, 2, ma_11_close_pos);
      prev_open = iOpen(_Symbol, _Period, 2);
      current_open = iClose(_Symbol, _Period, 1);
      /* CLOSING POSITIONS */
      if (
         (
            pos_info.PositionType() == POSITION_TYPE_SELL
            && prev_open > ma_11_close_pos[1]
            && current_open < ma_11_close_pos[0]
         ) ||
         (
            pos_info.PositionType() == POSITION_TYPE_BUY
            && prev_open < ma_11_close_pos[1]
            && current_open > ma_11_close_pos[0]
         )
      ) {
         Comment(
            "Position type ", pos_info.PositionType(),
            "\n",
            "Price open ", pos_info.PriceOpen()
         );
         trade.PositionClose(trade_ticket);  
      }
   } else {
      
      double Ask_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      double Bid_op = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      double diferential = Ask_op - Bid_op;
      if(diferential > 1) return;
      // if (ao_array[0] < 100 && ao_array[0] > -100) return;

      CopyBuffer(atr_14_handler, 0, 1, 1, atr_14_array);

      /* OPENING POSITIONS */
      if (
         // buy
         (
            candle_close > ma_265_array[0]
            && candle_close < ma_11_array[0]
            && (
               rsi_2_array[0] < 25
               && rsi_2_array[1] > rsi_2_array[0]
               && rsi_2_array[1] > 25
            )
         )
      ) {
         double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);   
         trade.Buy(1, _Symbol, Ask, Ask - (atr_14_array[0]), 0, (string)atr_14_array[0]); // TODO: SET STOP
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(300);
      } else if (
         // sell
         (
            candle_close < ma_265_array[0]
            && candle_close > ma_11_array[0]
            && (
               rsi_2_array[0] > 75
               && rsi_2_array[1] < rsi_2_array[0]
               && rsi_2_array[1] < 75
            )
         )
      ) {
         double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
         trade.Sell(1, _Symbol, Bid, Bid + (atr_14_array[0]), 0, (string)atr_14_array[0]);
         trade_ticket = trade.ResultOrder();
         time_passed = false;
         EventSetTimer(300);
      }
   } 
}

void OnTimer() {
   time_passed = true;
}

