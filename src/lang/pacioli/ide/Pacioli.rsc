module lang::pacioli::ide::Pacioli

import lang::pacioli::utils::Parse;
import SourceEditor;


public void registerPacioli() {
	registerLanguage("Pacioli", "pac", parsePacioli);
}