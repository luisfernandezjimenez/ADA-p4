How to compile: 

resolución de colisiones mediante encadenamiento.

    - gnatmake -I./hash_maps_g_chaining -I/usr/local/ll/lib chat_server_3.adb
    - gnatmake -I./hash_maps_g_chaining -I/usr/local/ll/lib chat_client_3.adb

resolución de colisiones mediante direccionamiento abierto.

    - gnatmake -I./hash_maps_g_open -I/usr/local/ll/lib chat_server_3.adb
    - gnatmake -I./hash_maps_g_open -I/usr/local/ll/lib chat_client_3.adb

How to execute:
    
    - ./chat_server_3 <port> <number_max_active_clients>
    - ./chat_client_3 <name_machine> <port> <name>

