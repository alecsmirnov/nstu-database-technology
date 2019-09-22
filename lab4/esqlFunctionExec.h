#ifndef ESQLFUNCTIONEXEC_HEC
#define ESQLFUNCTIONEXEC_HEC

#include <stdlib.h>
#include <string.h>

EXEC SQL INCLUDE "esqlFunctions.h";

#define ARGS_COUNT 4				// Количество входных параметров

typedef void (*func_ptr_t)();		// Указатель на функцию, исполняющую задачу

// Копирование строки в динамическую строку
static inline char* dynamicStrCpy(char* str) {
	char* new_str = (char*)malloc(sizeof(char) * strlen(str));
	strcpy(new_str, str);

	return new_str;
}

// Выполнить функцию с входными параметрами
static inline void functionExec(int argc, char* argv[], func_ptr_t func) {
	if (argc != ARGS_COUNT)
		fprintf(stderr, "Invalid count of command line items!\n");
	else {
		char* user_login    = dynamicStrCpy(argv[1]);
		char* user_password = dynamicStrCpy(argv[2]);
		char* user_scheme   = dynamicStrCpy(argv[3]);

		// Подключение к базе данных и схеме
		connectToDatabase(user_login, user_password);
		connectToScheme(user_scheme);

		// Исполнение переданной функции
		func();

		free(user_login);
		free(user_password);
		free(user_scheme);
	}
}

#endif