type WholeSale

parameters
	vat			: percentage
	salesPrice	: currency -- cents!
	purPrice	: currency
	coll		: natural
	pay			: natural
where
	salesPrice > purPrice


buffers
   assets		
	  Deb	: Debtors
	  Art	: Articles
	  Mon	: Money

   liabilities
	  Cred	: Creditors
	  VAT	: Value-Added Tax

transactions
	ColDeb	: Collect on Debtors
	PayVAT	: Pay VAT
	ColVAT	: Collect VAT
	Sal		: Sales
	Pur		: Purchase

derived
	salesVat = vat * salesPrice
	purVat = vat * purPrice

equations
	Deb	: salesPrice * Sal[Deb] - Col@coll[Deb]
	Art	: Pur[Art] - Sal[Art]
	Cred: purPrice * Pur[Cred] - Pay@pay[Cred]
	Mon	: ColDeb[Mon] + ColVar[Mon] - PayCred[Mon] - PayVAT[Mon]
	VAT	: salesVat * Sal[VAT] - PayVAT@salesVat[VAT] + ColVat@purVat[VAT] - purVat * Pur[VAT]

end