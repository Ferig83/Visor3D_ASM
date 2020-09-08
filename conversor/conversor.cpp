#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>

using namespace std;

struct VERTICE {
	float x,y,z;
};

struct TRIANGULO {
	VERTICE vertice1,vertice2,vertice3;
};


int main(int argc, char *argv[]) {

	string linea_comando = "";
	string nombre_archivo_destino;
	string linea;
	linea_comando = argv[1];

	ifstream archivo_obj;
	ofstream archivo_3d;

	archivo_obj.open(linea_comando);

	linea_comando.resize(linea_comando.size() - 4);
	nombre_archivo_destino = linea_comando + ".3d";
	archivo_3d.open(nombre_archivo_destino, ios::binary);

	vector <string> tokens;

	
	vector <VERTICE> vertice;


	//vector <TRIANGULO> triangulo;
	TRIANGULO triangulo;

	stringstream check1(linea);
	string intermediate;
	

	int indice_vertice = 0;
	while (archivo_obj) {
		        
			getline(archivo_obj,intermediate, (char) 10);
			if (intermediate.substr(0,2) == "v ") {
				cout << "VERTICES CARGADAS:" << endl;
				intermediate.erase(0,2);
				tokens.push_back(intermediate.substr(0,intermediate.find(" ")+1));
				intermediate.erase(0,intermediate.find(" ")+1);
				tokens.push_back(intermediate.substr(0,intermediate.find(" ")+1));
				intermediate.erase(0,intermediate.find(" ")+1);
				tokens.push_back(intermediate.substr(0,intermediate.find((char) 10)));

				
				VERTICE coordenada;
				coordenada.x = stof(tokens[0]);
				coordenada.y = stof(tokens[1]);
				coordenada.z = stof(tokens[2]);
				vertice.push_back(coordenada);		
					

					/*
				vertice[indice_vertice].x = stof(tokens[0]);
				vertice[indice_vertice].y = stof(tokens[1]);
				vertice[indice_vertice].z = stof(tokens[2]);
				indice_vertice++;
					*/

				cout << "----" << endl;
				tokens.clear();

			} 	
 				
	}

	archivo_obj.clear();
	archivo_obj.seekg(0, ios::beg);
	
	while (archivo_obj) {

			getline(archivo_obj,intermediate, (char) 10);
			if (intermediate.substr(0,2) == "f ") {

				TRIANGULO triangulo;

				cout << "TRIANGULOS CONECTADOS:" << endl;
				intermediate.erase(0,2);

				triangulo.vertice1.x = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].x;
			        triangulo.vertice1.y = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].y;
				triangulo.vertice1.z = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].z;
				intermediate.erase(0,intermediate.find("/")+1);
				intermediate.erase(0,intermediate.find("/")+1);
				intermediate.erase(0,intermediate.find(" ")+1);

				triangulo.vertice2.x = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].x;
			        triangulo.vertice2.y = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].y;
				triangulo.vertice2.z = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].z;
				intermediate.erase(0,intermediate.find("/")+1);
				intermediate.erase(0,intermediate.find("/")+1);
				intermediate.erase(0,intermediate.find(" ")+1);


				triangulo.vertice3.x = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].x;
			        triangulo.vertice3.y = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].y;
				triangulo.vertice3.z = vertice[(stoi(intermediate.substr(0,intermediate.find("/")+1)) - 1)].z;
				intermediate.erase(0,intermediate.find("/")+1);
				intermediate.erase(0,intermediate.find("/")+1);
				intermediate.erase(0,intermediate.find((char) 10)+1);


				cout << triangulo.vertice2.x << " " << triangulo.vertice2.y << " " << triangulo.vertice2.z;

				
				archivo_3d.write((char*) &triangulo.vertice1.x,4);
				archivo_3d.write((char*) &triangulo.vertice1.y,4);
				archivo_3d.write((char*) &triangulo.vertice1.z,4);
				archivo_3d.write((char*) &triangulo.vertice2.x,4);
				archivo_3d.write((char*) &triangulo.vertice2.y,4);
				archivo_3d.write((char*) &triangulo.vertice2.z,4);
				archivo_3d.write((char*) &triangulo.vertice3.x,4);
				archivo_3d.write((char*) &triangulo.vertice3.y,4);
				archivo_3d.write((char*) &triangulo.vertice3.z,4);
			
				
			}


							
		
	}




	
 	return 0;


}