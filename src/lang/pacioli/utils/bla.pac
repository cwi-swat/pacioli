type X
	buffers
	   assets		
		  Deb	: Debtors
		  Art	: Articles
		  Mon	: Money
	   end

	   liabilities
		  Cred: Creditors
		  VAT: Value Added Tax
	end
  end

  equations
	Deb	: salesPrice * Sal[Deb] - Col@coll[Deb]
	Art	: Pur[Art] - Sal[Art]
	Cred: purPrice * Pur[Cred] - Pay@pay[Cred]
	Mon	: ColDeb[Mon] + ColVar[Mon] - PayCred[Mon] - PayVAT[Mon]
	VAT	: salesVat * Sal[VAT] - PayVAT@salesVat[VAT] + ColVat@purVat[VAT] - purVat * Pur[VAT]
  end
 
end