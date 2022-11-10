//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

input int    IndicatorPeriod=14;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   MqlRates  rates_array[];
   string sSymbol=Symbol();
   string  sPeriod=EnumToString(Period());

   ArraySetAsSeries(rates_array,true);
   int MaxBar=TerminalInfoInteger(TERMINAL_MAXBARS);
   int iCurrent=CopyRates(sSymbol,Period(),0,MaxBar,rates_array);

   double ZeroIndicatorBuffer[];
   double FirstIndicatorBuffer[];
   SetIndexBuffer(0,ZeroIndicatorBuffer,INDICATOR_DATA);
   SetIndexBuffer(0,FirstIndicatorBuffer,INDICATOR_DATA);

   int to_copy = Bars(sSymbol,PERIOD_CURRENT);
   int zeroZigZag = iCustom(_Symbol, _Period, "../Indicators/Examples/ZigzagColor");
   int firstZigZag = iCustom(_Symbol, _Period, "../Indicators/Examples/ZigzagColor");

   CopyBuffer(zeroZigZag, 0, 0, to_copy, ZeroIndicatorBuffer);
   CopyBuffer(firstZigZag, 1, 0, to_copy, FirstIndicatorBuffer);
   ArraySetAsSeries(ZeroIndicatorBuffer, true);
   ArraySetAsSeries(FirstIndicatorBuffer, true);

   int fileHandle=FileOpen("indicator_data.csv",FILE_WRITE|FILE_CSV);

   for(int i = iCurrent-IndicatorPeriod-1; i > 0; i--)
     {
      string outputData=StringFormat("%s",TimeToString(rates_array[i].time,TIME_DATE));
      outputData += "," + TimeToString(rates_array[i].time,TIME_MINUTES);
      outputData += "," + (string)rates_array[i].high;
      outputData += "," + (string)rates_array[i].open;
      outputData += "," + (string)rates_array[i].close;
      outputData += "," + (string)rates_array[i].low;
      outputData += "," + DoubleToString(ZeroIndicatorBuffer[i], 2);
      outputData += "," + DoubleToString(FirstIndicatorBuffer[i], 2);
      outputData += "\n";

      FileWriteString(fileHandle,outputData);
     }

   FileClose(fileHandle);
   Comment(fileHandle);
  }
//+------------------------------------------------------------------+
