#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAX_CONTACTS 12
#define MAX_NAME 50
#define MAX_SURNAME 50
#define MAX_PHONE 15


struct Contact
{
    char name[MAX_NAME];
    char surname[MAX_SURNAME];
    char phoneNumber[MAX_PHONE];
};

void ReadContactFromFile(struct Contact contacts[], int *contactCount) {
    FILE *file = fopen("Tel.txt", "r");
    if (file == NULL)
    {
        printf("No file found");
    }

    *contactCount = 0;

    while (fscanf(file, "%s %s %s", contacts[*contactCount].name,
        contacts[*contactCount].surname,
        contacts[*contactCount].phoneNumber) != EOF){
            (*contactCount)++;
        }
    fclose(file);
}

void writeContactsToFile (struct Contact contacts[], int contactCount) {
    FILE *file = fopen("Tel.txt", "w");
    if (file == NULL) {
        printf("Error opening file for writing.\n");
        return;
    }

    for (int i = 0; i < contactCount; i++) {
        fprintf(file, "%s %s %s\n", contacts[i].name, contacts[i].surname, contacts[i].phoneNumber);
    }

    fclose(file);
}

void addContact (struct Contact contacts[], int *contactCount) {
    if (*contactCount < MAX_CONTACTS){
        printf("Enter name: ");
        scanf("%s", contacts[*contactCount].name);
        printf("Enter surname: ");
        scanf("%s", contacts[*contactCount].surname);
        printf("Enter phone number: ");
        scanf("%s", contacts[*contactCount].phoneNumber);

        (*contactCount)++;
        writeContactsToFile(contacts, *contactCount);

        printf("Contact added successfully.\n");
    } else {
        printf("Contact list is full.\n");
    }
}

void deleteFromFile (struct Contact contacts[], int *contactCount) {
    char name[MAX_NAME];
    char surname[MAX_SURNAME];
    printf("Enter name of contact to delete: ");
    scanf("%s", name);
    printf("Enter surname of contact to delete: ");
    scanf("%s", surname);

    int found = 0;
    for (int i = 0; i < *contactCount; i++) {
        if (strcmp(contacts[i].name, name) == 0 && strcmp(contacts[i].surname, surname) == 0) {
            for (int j = i; j < *contactCount - 1; j++) {
                contacts[j] = contacts[j + 1];
            }
            (*contactCount)--;
            found = 1;
            break;
        }
    }

    if (found) {
        writeContactsToFile(contacts, *contactCount);
        printf("Contact deleted successfully.\n");
    } else {
        printf("Contact not found.\n");
    }
}

void updateContact (struct Contact contacts[], int *contactCount) {
    char name[MAX_NAME];
    char surname [MAX_SURNAME];
    printf("Enter name of contact to update: ");
    scanf("%s", name);
    printf("Enter surname of contact to update: ");
    scanf("%s", surname);
    int found = 0;

    for (int i = 0; i < contactCount; i++)
    {
        if (strcmp(contacts[i].name, name) == 0 && strcmp(contacts[i].surname, surname) == 0) {
            printf("Enter new phone number: ");
            scanf("%s", contacts[i].phoneNumber);
            found = 1;
            break;
        }
    }
}

void displayContacts(struct Contact contacts[], int contactCount) {
    if (contactCount == 0 ){
        printf("No contacts in list");
        return;
    }
    printf("\n%-5s  %-20s %-20s %-15s","Index", "Name", "Surname", "Phone Number");
    printf("---------------------------------------------\n");
    for (int i = 0; i < contactCount; i++)
    {
        printf("%-5d:  %-20s   %-20s   %-15s",i+1, contacts[i].name, contacts[i].surname, contacts[i].phoneNumber);
    }
    
}

int main(){
    int concactCount = 0;
    struct Contact contacts[MAX_CONTACTS];

    
}
