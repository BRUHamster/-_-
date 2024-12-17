#include <iostream>
#include <pthread.h>
#include <unistd.h> // Для usleep()
#include <queue>   // Для буферов
#include <cstdlib> // Для rand()

#define MAX_DELAY 1000000  // Максимальная задержка в микросекундах

using namespace std;

// Буферы для передачи булавок между участками
queue<int> buffer1; // Участок 1 -> Участок 2
queue<int> buffer2; // Участок 2 -> Участок 3

// Мьютексы и условные переменные для синхронизации
pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex2 = PTHREAD_MUTEX_INITIALIZER;

pthread_cond_t cond1 = PTHREAD_COND_INITIALIZER;
pthread_cond_t cond2 = PTHREAD_COND_INITIALIZER;

int processedPins = 0; // Количество обработанных булавок
int NUM_PINS;          // Количество булавок вводит пользователь

// Поток 1: Проверка булавок на кривизну
void* section1(void* arg) {
    for (int i = 1; i <= NUM_PINS; ++i) {
        usleep(rand() % MAX_DELAY); // Случайная задержка

        pthread_mutex_lock(&mutex1); // Захват мьютекса для buffer1

        cout << "Space 1: Check " << i << " GoTo Buffer 1." << endl;
        buffer1.push(i); // Передача булавки в buffer1

        pthread_cond_signal(&cond1); // Сигнал участку 2, что булавка готова
        pthread_mutex_unlock(&mutex1); // Освобождение мьютекса
    }
    return nullptr;
}

// Поток 2: Заточка булавок
void* section2(void* arg) {
    while (true) {
        pthread_mutex_lock(&mutex1);
        while (buffer1.empty()) { // Ожидание булавки в buffer1
            pthread_cond_wait(&cond1, &mutex1);
        }
        int pin = buffer1.front();
        buffer1.pop();
        pthread_mutex_unlock(&mutex1);

        usleep(rand() % MAX_DELAY); // Заточка булавки

        pthread_mutex_lock(&mutex2); // Захват мьютекса для buffer2
        cout << "Space 2: Sharping items" << pin << " GoTo Buffer 2." << endl;
        buffer2.push(pin);
        pthread_cond_signal(&cond2); // Сигнал участку 3
        pthread_mutex_unlock(&mutex2);
    }
    return nullptr;
}

// Поток 3: Контроль качества булавок
void* section3(void* arg) {
    while (true) {
        pthread_mutex_lock(&mutex2);
        while (buffer2.empty()) { // Ожидание булавки в buffer2
            pthread_cond_wait(&cond2, &mutex2);
        }
        int pin = buffer2.front();
        buffer2.pop();
        pthread_mutex_unlock(&mutex2);

        usleep(rand() % MAX_DELAY); // Контроль качества
        cout << "Space 3: quality check " << pin << ".\n";

        processedPins++;
        if (processedPins == NUM_PINS) {
            break; // Завершение работы, если все булавки обработаны
        }
    }
    return nullptr;
}

int main() {
    srand(time(nullptr)); // Инициализация генератора случайных чисел

    pthread_t t1, t2, t3;

    // Ввод количества булавок
    cout << "Text Number of items: ";
    cin >> NUM_PINS;

    cout << "\nTime for work!\n";

    // Создание потоков
    pthread_create(&t1, nullptr, section1, nullptr);
    pthread_create(&t2, nullptr, section2, nullptr);
    pthread_create(&t3, nullptr, section3, nullptr);

    // Ожидание завершения потоков
    pthread_join(t1, nullptr);
    pthread_join(t3, nullptr);

    cout << "All done. good day.\n";

    return 0;
}
