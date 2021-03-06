Symbol[] symbols = Symbols.GetSymbols();

System.Text.StringBuilder text = new System.Text.StringBuilder("");

for(int i=0;i < symbols.Length;i++)
{
	Symbol sym = symbols[i];
	
	#append symbol
	text.AppendLine(sym.Name);
	
	HistoricalQuotes quotes = Quotes.GetHistoricalQuotes(sym.Name);

	#get quote
	System.Text.StringBuilder textQuotes = new System.Text.StringBuilder("");
	
	for(int j=0;j < quotes.Close.Length;j++)
		{
		textQuotes .AppendLine(sym.Name + ";" + quotes.Date[j].ToString("yyyy-MM-dd") + ";" + quotes.Close[j]+ ";" + quotes.Open[j] + ";" + quotes.High[j] + ";" + quotes.Low[j] + ";" + quotes.Volume[j]);

		}
	System.IO.File.AppendAllText(@"C:\Users\user\Documents\quantshare\quotes.csv", textQuotes.ToString());

}

System.IO.File.WriteAllText(@"C:\Users\user\Documents\quantshare\symbols.csv", text.ToString());