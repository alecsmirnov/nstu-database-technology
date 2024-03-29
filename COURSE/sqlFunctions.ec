#include "sqlFunctions.h"

#include <stdlib.h>

extern void errorHandle(const char* error_name);

// Очистка таблиц product_pdbi, product_cdb
void dbClearTable(const char* table_name) {
	EXEC SQL BEGIN DECLARE SECTION;
	char* sql_text = NULL;
	EXEC SQL END DECLARE SECTION;

	sql_text = (char*)malloc(sizeof(char) * (strlen(CLEAR_TABLE_PATTERN) + strlen(table_name) + 1));
	sprintf(sql_text, CLEAR_TABLE_PATTERN, table_name);

	EXEC SQL PREPARE query FROM :sql_text;
	EXEC SQL EXECUTE query;
	errorHandle("clear data");

	free(sql_text);
}

// Очистка последовательностей таблиц product_pdbi, product_cdb
void dbClearSequence(const char* table_name) {
	EXEC SQL BEGIN DECLARE SECTION;
	char* sql_text = NULL;
	EXEC SQL END DECLARE SECTION;

	sql_text = (char*)malloc(sizeof(char) * (strlen(CLEAR_SEQUENCE_PATTERN) + strlen(table_name) + 1));
	sprintf(sql_text, CLEAR_SEQUENCE_PATTERN, table_name);

	EXEC SQL PREPARE query FROM :sql_text;
	EXEC SQL EXECUTE query;
	errorHandle("clear sequence");

	free(sql_text);
}

// Вставка данных для таблиц product_pdbi, product_cdb
static void dbTableInsert(const char* table_name, const char* name, const char* operation) {
	EXEC SQL BEGIN DECLARE SECTION;
	char* sql_text = NULL;
	const char* sql_name = name;
	const char* sql_operation = operation;
	EXEC SQL END DECLARE SECTION;

	sql_text = (char*)malloc(sizeof(char) * (strlen(DB_INSERT_PATTERN) + strlen(table_name) + 1));
	sprintf(sql_text, DB_INSERT_PATTERN, table_name);

	EXEC SQL BEGIN WORK;

	EXEC SQL PREPARE query FROM :sql_text;
	EXEC SQL EXECUTE query USING :sql_name, :sql_operation;
	errorHandle("insert data");

	EXEC SQL COMMIT WORK;

	free(sql_text);
}

// Обновление данных для таблиц product_pdbi, product_cdb
static void dbTableUpdate(const char* table_name, const char* name, const char* operation) {
	EXEC SQL BEGIN DECLARE SECTION;
	char* sql_text = NULL;
	const char* sql_name = name;
	const char* sql_operation = operation;
	EXEC SQL END DECLARE SECTION;

	sql_text = (char*)malloc(sizeof(char) * (strlen(DB_UPDATE_PATTERN) + strlen(table_name) + 1));
	sprintf(sql_text, DB_UPDATE_PATTERN, table_name);

	EXEC SQL BEGIN WORK;

	EXEC SQL PREPARE query FROM :sql_text;
	EXEC SQL EXECUTE query USING :sql_name, :sql_operation;
	errorHandle("update data");

	EXEC SQL COMMIT WORK;

	free(sql_text);
}

// Удаление данных для таблиц product_pdbi, product_cdb
static void dbTableDelete(const char* table_name) {
	EXEC SQL BEGIN DECLARE SECTION;
	char* sql_text = NULL;
	EXEC SQL END DECLARE SECTION;

	sql_text = (char*)malloc(sizeof(char) * (strlen(DB_DELETE_PATTERN) + strlen(table_name) + 1));
	sprintf(sql_text, DB_DELETE_PATTERN, table_name);

	EXEC SQL PREPARE query FROM :sql_text;
	EXEC SQL EXECUTE query;
	errorHandle("delete data");

	free(sql_text);
}

// Вставка данныех в журнал
static void logTableInsert(const char* table_name, const char* operation, const char* n_condition, 
					const char* old_data, const char* new_data) {
	EXEC SQL BEGIN DECLARE SECTION;
	char* sql_text = NULL;
	EXEC SQL END DECLARE SECTION;

	sql_text = (char*)malloc(sizeof(char) * (strlen(LOG_INSERT_PATTERN) + strlen(table_name) + strlen(operation) + 
											 strlen(old_data) + strlen(new_data)  + strlen(n_condition)  + 1));
	sprintf(sql_text, LOG_INSERT_PATTERN, table_name, operation, old_data, new_data, n_condition);

	EXEC SQL BEGIN WORK;

	EXEC SQL PREPARE query FROM :sql_text;
	EXEC SQL EXECUTE query;
	errorHandle("log data insert");

	EXEC SQL COMMIT WORK;

	free(sql_text);
}

// Вставка данных с записью в журнал
void dbTableInsertLog(const char* table_name, const char* name, const char* operation) {
	dbTableInsert(table_name, name, operation);
	logTableInsert(table_name, operation, LOG_INSERT_CONDITION, "''", name);
}

// Обновление данных с записью в журнал
void dbTableUpdateLog(const char* table_name, const char* name, const char* operation) {
	char* log_condition = (char*)malloc(sizeof(char) * (strlen(LOG_UPDATE_CONDITION) + strlen(table_name) + 1));
	sprintf(log_condition, LOG_UPDATE_CONDITION, table_name);

	logTableInsert(table_name, operation, log_condition, "name", name);
	dbTableUpdate(table_name, name, operation);

	free(log_condition);
}

// Удаление данных с записью в журнал
void dbTableDeleteLog(const char* table_name, const char* operation) {
	char* log_condition = (char*)malloc(sizeof(char) * (strlen(LOG_DELETE_CONDITION) + strlen(table_name) + 1));
	sprintf(log_condition, LOG_DELETE_CONDITION, table_name);

	logTableInsert(table_name, operation, log_condition, "name", "");
	dbTableDelete(table_name);

	free(log_condition);
}

// Репликация данных
void dbReplication() {
	EXEC SQL BEGIN DECLARE SECTION;
	const char* sql_lock_text = LOCK_TABLE_PATTERN;
	const char* sql_gen_log_insert_text = GENERAL_LOG_INSERT_PATTERN;
	const char* sql_log_filter_text = LOG_FILTER_PATTERN;
	const char* sql_replication_text = REPLICATION_PATTERN;
	EXEC SQL END DECLARE SECTION;

	EXEC SQL BEGIN WORK;

	EXEC SQL PREPARE query FROM :sql_lock_text;
	EXEC SQL EXECUTE query;
	errorHandle("data lock");

	EXEC SQL PREPARE query FROM :sql_gen_log_insert_text;
	EXEC SQL EXECUTE query;
	errorHandle("general log data insert");

	EXEC SQL PREPARE query FROM :sql_log_filter_text;
	EXEC SQL EXECUTE query;
	errorHandle("log filter");

	dbClearTable(table_list[TABLE_LIST_CDB]);
	dbClearSequence(table_list[TABLE_LIST_CDB]);

	EXEC SQL PREPARE query FROM :sql_replication_text;
	EXEC SQL EXECUTE query;
	errorHandle("data replication");

	EXEC SQL COMMIT WORK;
}