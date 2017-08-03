package integration;

import java.io.File;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

import org.eclipse.rdf4j.model.IRI;
import org.eclipse.rdf4j.model.Statement;
import org.eclipse.rdf4j.model.vocabulary.RDF;
import org.eclipse.rdf4j.repository.Repository;
import org.eclipse.rdf4j.repository.RepositoryConnection;
import org.eclipse.rdf4j.repository.RepositoryException;
import org.eclipse.rdf4j.repository.RepositoryResult;
import org.eclipse.rdf4j.repository.sail.SailRepository;
import org.eclipse.rdf4j.rio.RDFFormat;
import org.eclipse.rdf4j.rio.RDFParseException;
import org.eclipse.rdf4j.sail.memory.MemoryStore;

public class TerminologyInstance implements Terminology {

	private IRI terminologyIRI;
	private String instanceNamespace;
	
	Set<IRI> instances = new HashSet<IRI>();
	
	public boolean isInstance(IRI instanceIRI) {
		return(instances.contains(instanceIRI));
	}
	
	public boolean isInstance(String instanceName) {
		return(isInstance(Util.vf.createIRI(instanceNamespace, instanceName)));
	}

	public IRI getTerminologyIRI() {
		return terminologyIRI;
	}
	
	public TerminologyInstance(File rdfFile, RDFFormat RDFformat, IRI classOfInstance){
		this.instanceNamespace = classOfInstance.getNamespace();
		// p RDF triple in memory : 
		Repository rep = new SailRepository(new MemoryStore());
		rep.initialize();
		RepositoryConnection con = rep.getConnection();
		try {
			con.add(rdfFile, null, RDFformat);
		} catch (RDFParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (RepositoryException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
				
		RepositoryResult<Statement> results = con.getStatements(null, RDF.TYPE, classOfInstance);
		while(results.hasNext()){
			Statement stat = results.next();
			instances.add((IRI) stat.getSubject()); 
		}
	}
	
	public static void main(String args[]){
		File rdfFile = new File("terminology/codesFINESS.ttl");
		//String baseURI = EIG.NAMESPACE;
		IRI classOfInstance = Util.vf.createIRI(EIG.NAMESPACE, "Etablissement");
		System.out.println(classOfInstance.stringValue());
		TerminologyInstance terminologyInstance = new TerminologyInstance(rdfFile, 
				RDFFormat.TURTLE, classOfInstance);
		System.out.println(terminologyInstance.instances.size());
		System.out.println(terminologyInstance.isInstance("Etablissement3300002172"));
	}

}
