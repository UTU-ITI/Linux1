Parte Práctica - Evaluación de Competencias
Temas Evaluados:
✅ Permisos y seguridad de archivos
✅ Bash scripting básico
✅ Administración de red en Linux

Ejercicio 1: Permisos de archivos y directorios (6 puntos)
Realiza las siguientes tareas y proporciona capturas de pantalla o descripciones detalladas de los comandos utilizados:

Crea un archivo llamado datos.conf en tu directorio de usuario y cambia su propietario a root.

Modifica los permisos del archivo para que:

Solo el usuario root pueda leer y escribir.

El grupo solo pueda leer.

Otros no tengan acceso.

Verifica los permisos con ls -l y explica su significado.

Crea un directorio privado en tu home y restringe su acceso solo a tu usuario.

Ejercicio 2: Bash Scripting (7 puntos)
Crea un script en Bash llamado backup.sh que cumpla con los siguientes requisitos:

Acepte un nombre de usuario como argumento.

Cree un respaldo del directorio /home/<usuario>/Documentos en /tmp/backup_<usuario>.tar.gz.

Muestra un mensaje indicando que el respaldo se ha realizado con éxito.

Ejemplo de uso:

bash
Copy
Edit
./backup.sh usuario1
✅ Entrega el código del script y una captura de su ejecución exitosa.

Ejercicio 3: Administración de Red (7 puntos)
Realiza los siguientes comandos y describe su propósito y salida en una breve explicación:

Verifica la configuración IP de tu equipo.

bash
Copy
Edit
ip a
Muestra la ruta de los paquetes hacia google.com.

bash
Copy
Edit
traceroute google.com
Muestra el estado de todas las conexiones activas.

bash
Copy
Edit
netstat -tulnp
Crea una regla de firewall con iptables que bloquee las conexiones SSH desde cualquier IP externa.

bash
Copy
Edit
sudo iptables -A INPUT -p tcp --dport 22 -j DROP
✅ Entrega la salida de los comandos y una explicación de cada uno.

Puntaje total: 20 puntos
💡 Criterios de evaluación:

Uso correcto de comandos y sintaxis.

Explicaciones claras y concisas.

Capturas o salida de los comandos ejecutados correctamente.

Si necesitas ajustes, dime. 🚀






You said:
podes hacerme lo mismo para semana dos, tres y cuatro


ChatGPT said:
¡Perfecto! A continuación, te presento las actividades prácticas para Semana 2, Semana 3 y Semana 4, con una estructura coherente con lo que ya estás usando en el curso "Introducción a Linux".

🔧 Semana 2 - Práctica: Permisos y Usuarios
Temas Evaluados:
Gestión de usuarios y grupos

Permisos de archivos y directorios

Comandos chmod, chown, usermod, adduser

Actividades:
🧪 Ejercicio 1: Gestión de Usuarios (6 puntos)
Crea un usuario llamado alumno1 con contraseña.

Crea un grupo llamado grupo_tec.

Agrega alumno1 al grupo grupo_tec.

Verifica con groups alumno1 que el usuario fue agregado correctamente.

Modifica el shell por defecto del usuario alumno1 a /bin/bash.

🧪 Ejercicio 2: Permisos de Archivos (6 puntos)
Crea un archivo informe.txt y dale permisos rw-r--r--.

Cambia el propietario del archivo a alumno1 y grupo a grupo_tec.

Explica qué significan los permisos con ls -l informe.txt.

🧪 Ejercicio 3: Umask y permisos por defecto (3 puntos)
Verifica el valor actual de umask.

Crea un archivo y un directorio, verifica los permisos por defecto.

Modifica la umask temporalmente a 027 y repite el proceso.

💬 Pregunta de reflexión (5 puntos):
¿Por qué es importante restringir correctamente los permisos de archivos y carpetas en un entorno multiusuario?

🗃️ Semana 3 - Práctica: Bash Scripting y Automatización
Temas Evaluados:
Variables, condicionales y bucles en Bash

Uso de scripts para automatizar tareas

Lectura de parámetros desde la línea de comandos

Actividades:
🧪 Ejercicio 1: Script de Bienvenida (4 puntos)
Crea un script bienvenida.sh que:

Pida el nombre del usuario y lo salude.

Muestre la fecha y hora actual.

Informe el nombre del usuario logueado y su directorio home.

🧪 Ejercicio 2: Script con Parámetros (6 puntos)
Crea un script multiplicar.sh que:

Reciba dos números como argumentos.

Multiplique los números y muestre el resultado.

Detecte si faltan argumentos y muestre un mensaje de uso.

bash
Copy
Edit
./multiplicar.sh 4 5
Resultado: 20
🧪 Ejercicio 3: Bucle con Condicional (6 puntos)
Crea un script contador.sh que:

Recorra los números del 1 al 10.

Indique si el número es par o impar en cada iteración.

💬 Pregunta de reflexión (4 puntos):
¿Qué ventajas ofrece usar scripts en tareas administrativas repetitivas?

🌐 Semana 4 - Práctica: Red, Servicios y Documentación
Temas Evaluados:
Comandos de red (ping, ip, netstat, traceroute)

Comprobación de servicios y puertos

Uso de man y ayuda integrada

Actividades:
🧪 Ejercicio 1: Diagnóstico de red (5 puntos)
Usa ip a para identificar tu dirección IP.

Usa ping 8.8.8.8 para verificar conectividad.

Usa traceroute www.google.com y explica qué muestra.

🧪 Ejercicio 2: Estado de servicios (5 puntos)
Usa netstat -tulnp o ss -tulnp para listar puertos abiertos.

Verifica si el servicio ssh está corriendo con systemctl status ssh.

Muestra cómo reiniciar un servicio.

🧪 Ejercicio 3: Manuales y ayuda (6 puntos)
Usa man para explorar la ayuda de los siguientes comandos:

ls

grep

chmod

Copia al menos una opción útil de cada uno con una breve explicación.

💬 Pregunta de reflexión (4 puntos):
¿Por qué es importante saber interpretar el estado de red y los servicios del sistema?

¿Querés que lo deje en formato Markdown para pasarlo a GitHub, o lo agregamos al documento directamente?






You said:
si por favor


ChatGPT said:
Edited Introduccion Linux

Answer in chat instead
¡Perfecto! Ya incorporé las nuevas diapositivas sobre permisos y usuarios a tu presentación. Aquí tenés el material actualizado para las semanas 3 y 4:

Diapositiva 14: Permisos de Archivos
🔐 Permisos en Linux (modo simbólico y numérico)
Cada archivo/directorio tiene 3 tipos de permisos para 3 tipos de usuarios:

👤 Usuarios:

u (usuario propietario)

g (grupo)

o (otros)

🔑 Permisos:

r (lectura)

w (escritura)

x (ejecución)

📊 Ejemplo de salida con ls -l:
-rwxr-xr-- 1 juan alumnos 1024 abr 9 13:00 script.sh

Diapositiva 15: Permisos - Representación Numérica
🔢 Códigos numéricos (suma de bits por tipo de permiso):

Permiso	Valor
r	4
w	2
x	1
---	0
📌 Ejemplo:
chmod 754 script.sh → rwxr-xr--

7 (4+2+1): usuario

5 (4+0+1): grupo

4 (4+0+0): otros

✏️ Práctica: Cambia permisos con chmod

Diapositiva 16: Cambiar Dueño y Grupo
🔧 Comandos útiles

Cambiar propietario: chown usuario archivo

Cambiar grupo: chgrp grupo archivo

Ambos: chown usuario:grupo archivo

📌 Ejemplo:
chown ana:proyectos informe.txt

🔒 Solo el superusuario (root) puede cambiar propietarios

Diapositiva 17: Gestión de Usuarios
👥 Usuarios en Linux

Cada usuario tiene un UID (User ID)

Información en /etc/passwd

Grupos en /etc/group

🔧 Comandos básicos:

Crear usuario: sudo adduser nombre

Borrar usuario: sudo deluser nombre

Cambiar contraseña: passwd usuario

🛠 Ejercicio: Crear un usuario nuevo y cambiarle la contraseña

Diapositiva 18: Gestión de Grupos
👨‍👩‍👧‍👦 Grupos de usuarios

Permiten asignar permisos colectivos

🔧 Comandos útiles:

Crear grupo: sudo addgroup grupo

Añadir usuario a grupo: sudo usermod -aG grupo usuario

Ver grupos del usuario: groups usuario

📌 Ejemplo:
sudo usermod -aG audio juan → Agrega a “juan” al grupo “audio”

✏️ Ejercicio: Crear un grupo y agregar un usuario
