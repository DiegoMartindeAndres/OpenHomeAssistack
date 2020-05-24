#  Implementación de un sistema de gestión domótica para dispositivos IoT desplegado en una arquitectura basada en computación en la niebla.

El objetivo de este proyecto es desplegar un escenario virtual compuesto por una red residencial, una instancia de Open Source Mano formada por un contenedor Docker (Home Assistant) que emula su instanciación en una central local, y una red externa con conectividad a Internet y a un servidor virtual. 

En este proyecto se va a utilizar la plataforma de código abierto Open Source Mano (OSM) para profundizar en las funciones de red virtualizadas y su orquestación. El escenario que se va a desplegar está inspirado en la transformación de las centrales locales a centros de datos que permiten reemplazar servicios de red ofrecidos mediante hardware específico y propietario por servicios de red definidos por software sobre hardware de propósito general. Las funciones de red que se despliegan en estas centrales se gestionan mediante una plataforma de orquestación conocida como Open Source Mano. 

Se pretende demostrar que es posible desplegar una instancia Home Assistant en una central local definida por software con plena conectividad tanto interna como externa. 

Adicionalmente, se pretende dotar al escenario de protección frente a caídas de conectividad instalando una instancia secundaria de Home Assistant en la red residencial, la cual realiza un pull periódico al fichero de configuración de la instancia primaria en la central local, estando así sincronizada y lista para funcionar en caso de caída del servicio principal.  



## Comenzando 🚀

Para desplegar el proyecto en tu máquina virtual, es necesario:

- Descargar la maquina virtual VNXSDNNFVLAB2020-v1.ova desde https://idefix.dit.upm.es/download/vnx/vnx-vm/VNXSDNNFVLAB2020-v1.ova

- Desplegarla con VirtualBox (o similar) asignandole al menos 6GB de RAM (recomendado).

- Realizar un git clone del repositorio https://github.com/DiegoMartindeAndres/OpenHomeAssistack.git.



## Pre-requisitos 📋

- Es necesario contar con un ordenador con capacidad de virtualización y una herramienta VirtualBox o similar.

- Es recomendable que la maquina cuente con al menos 8GB de RAM.



## Instalación 🔧
	
	Paso 1: Dirigirse a la carpeta previamente descargada del repositorio.

	Paso 2: Crear la imagen docker que va a implementar la VNF mediante el fichero Dockerfile que se encuentran en el directorio “vnf-img2” usando los comandos "cd vnf-img2" y "sudo docker build -t vnf-img2 ."

	Paso 3: Dirigirse a "https://localhost/auth/?next=/" e ingresar "admin" tanto en usuario en contraseña.

	Paso 4: Agregar en NS Packages el fichero previamente descargado "ns-vcpe.tar.gz".

	Paso 5: Agregar en VNF Packages el fichero previamente descargado "vnf-home.tar.gz".

	Paso 6: Ejecutar en la terminal el comando osm vim-list para conocer el nombre de la instancia VIM (ej: emu-vimXX).

	Paso 7: Dirigirse a la carpeta previamente clonada de github y ejecutar ./init.sh para crear los openvswitch AccessNet y ExtNet.

	Paso 8: Desde esa misma carpeta, ejecutar sudo bash vcpe1.sh para iniciar el despliegue del escenario.

	Paso 9: Ingresar en la petición Ns name: vcpe-1

	Paso 10: Ingresar en la petición Nsd name: vCPE

	Paso 11: Ingresar en la petición Vim account el nombre la instancia obtenida en el paso 4.

	Paso 12 : Esperar a que el script termine de ejecutarse (puede durar varios minutos, se indica el final cuando las trazas equivalen a "IPv4 is up").

	Paso 13: Acceso desde el navegador del host a la direccion externa de r1 (inspeccionarla mediante el comando ifconfig) en el puerto 1883.

	Paso 14: Ingreso de los parámetros de registro y reinicio del servidor para que se aplique la nueva configuración.

	Paso 14: Ejecucion desde h11 (o h12) del fichero sensor.py (o sensor2.py) mediante el comando "python3 sensor.py" (una vez se ejecute, se indicara el topic al que se le deben mandar los mensajes de control en las trazas de ejecución).

	Paso 15: Envio de mensajes desde MQTT (en Developer Tools de Home Assistant) hacia el sensor.py mediante la introduccion de un topic y el mensaje ON u OFF (si es el termostato los valores permitidos son 16,17,18,19,20,21,22,23,24,25,26).

	Paso 16: Confirmar la recepcion de las ordenes en la consola de h11.



## Pruebas de conectividad y funcionamiento ⚙️

Cuando el script finalice, se puede realizar las siguientes pruebas para comprobar que el escenario se ha arrancado correctamente:

- Ping desde h11/h12/br1 a 8.8.8.8 (conectividad externa).
- Ping desde la instancia docker a 8.8.8.8 (conectividad externa).
- Curl o wget desde s1 a 10.2.3.1:8123 para comprobar la redirección de la ip publica del servicio general a la ip privada de Home Assistant, obteniendo satisfactoriamente un fichero index.html.



## Pruebas de tolerancia a fallos 🔩

Una vez puesto en marcha el escenario y comprobado su correcto funcionamiento, se puede probar la tolerancia a fallos de conexión externa realizando el siguiente comando:

- Desde br1: ifdown eth2

Se debe comprobar como se despliega automaticamente en br1 una instancia secundaria de Home Assistant con la misma configuración que tenía la instancia principal en la central local. Se puede acceder a ella con el navegador del host mediante la  direccion IP externa asignada a br1. Es necesario un reinicio de Home Assistant una vez se haya desplegado.



## Notas adicionales para el despliegue 📦

- En caso de que en OSM el VIM no esté correctamente enlazado en el menú VIM Accounts, inicialice vim-emu tecleando el comando: "osm-restart-vimemu".

- Suele ser necesario hacer un restart de la instancia Home Assistant para que se recargue la nueva configuración. Esto se hacer desde el menú Configuración, dirigiéndose a la pestaña de Controles de Servidor.

- Para acceder al contenedor de la VNF instanciada se debe ejecutar:

		Ventana para VNF:home --> sudo docker exec -it mn.dc1_vcpe-1-1-ubuntu-1 bash



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
