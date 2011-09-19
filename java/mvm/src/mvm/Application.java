package mvm;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Application implements Expression {

	private Expression function;
	private List<Expression> arguments;

	public Application(Expression fun, List<Expression> args) {
		function = fun;
		arguments = args;
	}

	public PacioliValue eval(Environment env) throws IOException {
		if (function instanceof Variable) {
			String name = ((Variable) function).getName();
			List<PacioliValue> params = new ArrayList<PacioliValue>();
			for (Expression exp: arguments) {
				params.add(exp.eval(env));
			}
			if (name.equals("join")) {
				Matrix x = (Matrix) params.get(0);
				Matrix y = (Matrix) params.get(1);
				return x.join(y);
			} else if (name.equals("transpose")) {
				Matrix matrix = (Matrix) params.get(0);
				return matrix.transpose();
				
			} else if (name.equals("total")) {
				Matrix matrix = (Matrix) params.get(0);
				return matrix.total();
				
			} else if (name.equals("multiply")) {
				Matrix x = (Matrix) params.get(0);
				Matrix y = (Matrix) params.get(1);
				return x.multiply(y);
				
			} else if (name.equals("reciprocal")) {
				Matrix matrix = (Matrix) params.get(0);
				return matrix.reciprocal();
			} else if (name.equals("negative")) {
				Matrix matrix = (Matrix) params.get(0);
				return matrix.negative();
			} else if (name.equals("sum")) {
				Matrix x = (Matrix) params.get(0);
				Matrix y = (Matrix) params.get(1);
				return x.sum(y);
			} else if (name.equals("columns")) {
				Matrix matrix = (Matrix) params.get(0);
				List<PacioliValue> columns = new ArrayList<PacioliValue>();
				for (Matrix mat: matrix.columns()) {
					columns.add(mat);
				}
				return new PacioliList(columns);
				
			} else if (name.equals("rows")) {
				Matrix matrix = (Matrix) params.get(0);
				List<PacioliValue> rows = new ArrayList<PacioliValue>();
				for (Matrix mat: matrix.rows()) {
					rows.add(mat);
				}
				return new PacioliList(rows);
				
			} else if (name.equals("iter")) {
				Closure fun = (Closure) params.get(0);
				PacioliList list = (PacioliList) params.get(1);
				List<PacioliValue> tmp = new ArrayList<PacioliValue>();
				for (PacioliValue value: list.items()) {
					// todo: better
					List<PacioliValue> temp = new ArrayList<PacioliValue>();
					temp.add(value);
					PacioliList yo = (PacioliList) fun.apply(temp);
					for (PacioliValue item: yo.items()) {
						tmp.add(item);	
					}
				}
				if (tmp.size() == 1) {
					return tmp.get(0);
				} else {
					return new PacioliList(tmp);
				}
				
			} else if (name.equals("single")) {
				PacioliValue item = params.get(0);
				List<PacioliValue> tmp = new ArrayList<PacioliValue>();
				tmp.add(item);
				return new PacioliList(tmp);
				
			} else {
				throw new IOException(String.format("expected function but found '%s'", name));
			}
		} else {
			PacioliValue fun = function.eval(env);
			if (fun instanceof Closure) {
				List<PacioliValue> params = new ArrayList<PacioliValue>();
				for (Expression exp: arguments) {
					params.add(exp.eval(env));
				}
				return ((Closure) fun).apply(params); 
			} else {
				throw new IOException("A function application needs a function" + fun.getClass().toString());
			}
		}
	}
}
