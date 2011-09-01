import java.io.IOException;


public class MVM {
	
	public static void main(String[] args) {
		
		boolean verbose = false;
		String fileName;
		
		if (args.length == 1) {
			
			fileName = args[0];
			
		} else if (args.length == 2) {
			
			if (args[0].equals("-v")) {
				verbose = true;
			} else {
				System.out.println("Option " + args[0] + " unknown");
				return;
			}
			fileName = args[1];
			
		} else {
			System.out.println("Error: give a program filename as argument. Option -v for verbose output.");
			return;
		}
		
		Machine vm = new Machine();
		vm.verbose = verbose;
		
		try {
			vm.run(fileName, System.out);
		} catch (IOException e) {
			if (verbose) {
				System.out.println("\nState when error occured:\n");
				vm.dumpTypes(System.out);
				System.out.println();
				vm.dumpState(System.out);
			}
			System.out.println("\n\nError " + e.getLocalizedMessage());
		}
	}
}
