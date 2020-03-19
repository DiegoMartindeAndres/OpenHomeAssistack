#  Implementación de un sistema de gestión domótica para dispositivos IoT desplegado en una arquitectura basada en computación en la niebla.

El objetivo de este proyecto es desplegar un escenario virtual compuesto por una red residencial, una instancia de Open Source Mano formada por dos contenedores Docker (Home Assistant y vCPE) que emula una central local, y una red externa con conectividad a Internet y a un servidor virtual. 

En este proyecto se va a utilizar la plataforma de código abierto Open Source Mano (OSM) para profundizar en las funciones de red virtualizadas y su orquestación. El escenario que se va a desplegar está inspirado en la transformación de las centrales locales a centros de datos que permiten reemplazar servicios de red ofrecidos mediante hardware específico y propietario por servicios de red definidos por software sobre hardware de propósito general. Las funciones de red que se despliegan en estas centrales se gestionan mediante una plataforma de orquestación conocida como Open Source Mano. 

Se pretende demostrar que es posible desplegar una instancia Home Assistant en una central local definida por software con plena conectividad tanto interna como externa. 

Adicionalmente, se pretende dotar al escenario de protección frente a caídas de conectividad instalando una instancia secundaria de Home Assistant en la red residencial, la cual realiza un pull periódico al fichero de configuración de la instancia primaria en la central local, estando así sincronizada y lista para funcionar en caso de caída del servicio principal.  



## Comenzando 🚀

Para desplegar el proyecto en tu máquina virtual, es necesario:

- Descargar la maquina virtual VNXSDNNFVLAB2020-v1.ova desde https://idefix.dit.upm.es/download/vnx/vnx-vm/VNXSDNNFVLAB2020-v1.ova

- Desplegarla con VirtualBox (o similar) asignandole al menos 6GB de RAM.

- Realizar un git clone de https://github.com/jalvarezmari/TFM.



## Pre-requisitos 📋

- Es necesario contar con un ordenador con capacidad de virtualización y una herramienta VirtualBox o similar.

- Es recomendable que la maquina cuente con al menos 8GB de RAM.



## Instalación 🔧

	Paso 1: Dirigirse a "https://localhost/auth/?next=/" e ingresar "admin" tanto en usuario en contraseña.

	Paso 2: Agregar en NS Packages el fichero previamente descargado "ns-vcpe.tar.gz".

	Paso 3: Agregar en VNF Packages los ficheros previamente descargados "vnf-home.tar.gz" y "vnx-vcpe.tar.gz".

	Paso 4: Ejecutar en la terminal el comando osm vim-list para conocer el nombre de la instancia VIM (ej: emu-vimXX).

	Paso 5: Dirigirse a la carpeta previamente clonada de github y ejecutar ./init.sh para crear los openvswitch AccessNet y ExtNet.

	Paso 6: Desde esa misma carpeta, ejecutar sudo bash ./startAll.sh para iniciar el despliegue del escenario.

	Paso 7: Ingresar en la petición Ns name: vcpe-1

	Paso 8: Ingresar en la petición Nsd name: vCPE

	Paso 9: Ingresar en la petición Vim account el nombre la instancia obtenida en el paso 4.



## Pruebas de conectividad ⚙️

Cuando el script finalice, se puede realizar las siguientes pruebas para comprobar que el escenario se ha arrancado correctamente:

- Ping desde h11/h12/br1 a 8.8.8.8 (conectividad externa).
- Ping desde las dos instancias docker a 8.8.8.8 (conectividad externa).
- Curl o wget desde s1 a 10.2.3.1:8123 para comprobar la redirección de la ip publica del servicio general a la ip privada de Home Assistant, obteniendo satisfactoriamente un fichero index.html.



## Pruebas de tolerancia a fallos 🔩

Una vez puesto en marcha el escenario y comprobado su correcto funcionamiento, se puede probar la tolerancia a fallos de conexión externa realizando el siguiente comando:

- Desde br1: ifdown eth2

Se debe comprobar como se despliega automaticamente en br1 una instancia secundaria de Home Assistant con la misma configuración que tenía la instancia principal en la central local.



## Notas adicionales para el despliegue 📦

- En caso de que en OSM el VIM no esté correctamente enlazado en el menú VIM Accounts, inicialice vim-emu tecleando el comando: osm-restart-vimemu .

- Suele ser necesario hacer un restart de la instancia Home Assistant para que se recargue la nueva configuración. Esto se hacer desde el menú Configuración, dirigiéndose a la pestaña de Controles de Servidor.

- Para acceder a los contenedores de las VNF instanciadas se debe ejecutar:

		Ventana para VNF:home --> sudo docker exec -it mn.dc1_vcpe-1-1-ubuntu-1 bash

		Ventana para VNF:vcpe --> sudo docker exec -it mn.dc1_vcpe-1-2-ubuntu-1 bash



## Construido con 🛠️

* [VNX](https://web.dit.upm.es/vnxwiki/index.php/Main_Page) - Open-source virtualization tool
* [HomeAssistant](https://www.home-assistant.io/) - Smart Hub
* [OpenSourceMano](https://osm.etsi.org/) - Open Source Management and Orchestration (MANO)


## Wiki 📖

Puedes encontrar mucho más de cómo utilizar este proyecto en el Trabajo de Fin de Máster de José Antonio Álvarez Marí (Servicio biblioteca UPM).



## Autores ✒️

* **José Antonio Álvarez Marí** - *Trabajo de Fin de Máster* - (https://github.com/jalvarezmari)



## Licencia 📄

José Antonio Álvarez Marí - 2020 - UPM



## Expresiones de Gratitud 🎁

Gracias a mis tutores Diego Martín de Andrés y a David Fernández Cambronero por la ayuda recibida durante el desarrollo y la puesta en marcha de este proyecto.
