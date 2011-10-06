package mvm;

import java.io.IOException;
import java.io.Reader;
import java.io.StreamTokenizer;


public class Tokenizer {
	
	StreamTokenizer tokenizer;

	public int ttype;
	
	public static final int TT_EOF = StreamTokenizer.TT_EOF;
	public static final int TT_WORD = StreamTokenizer.TT_WORD;
	public static final int TT_NUMBER = StreamTokenizer.TT_NUMBER;
	
	public Tokenizer(Reader reader) {
		
		tokenizer = new StreamTokenizer(reader);
	
		tokenizer.ordinaryChar('-');
		tokenizer.ordinaryChars('0','9');
		tokenizer.wordChars('_', '_');
		tokenizer.ordinaryChar('/');   
		tokenizer.commentChar('#');
		tokenizer.ordinaryChar('.');
	}

	public int nextToken() throws IOException {
		int token = tokenizer.nextToken();
		ttype = tokenizer.ttype;
		return token;
	}

	public String sval() {
		return tokenizer.sval;
	}

	public int lineno() {
		return tokenizer.lineno();
	}

	public void pushBack() {
		tokenizer.pushBack();
	}
}