package mvm;

import java.io.IOException;
import java.io.Reader;
import java.io.StreamTokenizer;

import org.apache.commons.math.fraction.BigFraction;

import units.UnitSystem;


public class Tokenizer {
	
	StreamTokenizer tokenizer;
	UnitSystem unitSystem;
	public int ttype;
	
	public static final int TT_EOF = StreamTokenizer.TT_EOF;
	public static final int TT_WORD = StreamTokenizer.TT_WORD;
	public static final int TT_NUMBER = StreamTokenizer.TT_NUMBER;
	
	public Tokenizer(Reader reader, UnitSystem system) {
		
		tokenizer = new StreamTokenizer(reader);
		unitSystem = system;
		
		tokenizer.ordinaryChar('-');
		tokenizer.ordinaryChars('0','9');
		tokenizer.wordChars('_', '_');
		tokenizer.ordinaryChar('/');   
		tokenizer.commentChar('#');
		tokenizer.ordinaryChar('.');
	}

	public int nextToken() throws IOException {
		//return tokenizer.nextToken();
		int token = tokenizer.nextToken();
		ttype = tokenizer.ttype;
		//System.out.println(token);
		return token;
	}

	public String sval() {
		return tokenizer.sval;
	}

	public BigFraction nval() {
		//return null;
		return new BigFraction(tokenizer.nval);
	}
	
	public int lineno() {
		return tokenizer.lineno();
	}


	public void pushBack() {
		tokenizer.pushBack();
	}

//	public Double dval() {
//		return tokenizer.nval;
//	}

}