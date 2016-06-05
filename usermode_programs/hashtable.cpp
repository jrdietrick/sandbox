#include "userlib"
#include "hashtable.h"


Hashtable::Hashtable (
    int bucket_count
    ) : bucket_count_(bucket_count)
{
    buckets_ = new Node*[bucket_count]();
}

Hashtable::~Hashtable (
    )
{
    if (buckets_) {
        for (int i = 0; i < bucket_count_; i++) {
            Node* current = buckets_[i];
            Node* next = nullptr;
            while (current) {
                next = current->next_;
                delete[] current->key_;
                delete current;
                current = next;
            }
        }
        delete[] buckets_;
    }
}

Hashtable::Hashtable (
    const Hashtable& other
    )
{
    assert(false);
}

Hashtable& Hashtable::operator= (
    const Hashtable& other
    )
{
    assert(false);
}

int Hashtable::hash (
    char* key
    )
{
    int hash_value = 0;
    while (*key != 0) {
        hash_value = (31 * hash_value + *key) % bucket_count_;
        key++;
    }
    return hash_value;
}

void* Hashtable::get_or_remove (
    char* key,
    bool delete_when_found
    )
{
    int bucket = hash(key);
    Node* cursor = buckets_[bucket];
    Node** incoming_link = &buckets_[bucket];
    while (cursor) {
        if (strcmp(cursor->key_, key) == 0) {
            assert(cursor->value_ != nullptr);
            void* found_value = cursor->value_;
            if (delete_when_found) {
                *incoming_link = cursor->next_;
                delete[] cursor->key_;
                delete cursor;
            }
            return found_value;
        }
        incoming_link = &cursor->next_;
        cursor = cursor->next_;
    }
    return nullptr;
}

bool Hashtable::contains (
    char* key
    )
{
    return get(key) != nullptr;
}

void* Hashtable::get (
    char* key
    )
{
    return get_or_remove(key, false);
}

void* Hashtable::remove (
    char* key
    )
{
    return get_or_remove(key, true);
}

void Hashtable::put (
    char* key,
    void* value
    )
{
    assert(value != nullptr);
    assert(!contains(key));
    int bucket = hash(key);

    Node* new_node = new Node();
    new_node->next_ = nullptr;
    new_node->key_ = new char[strlen(key) + 1];
    strcpy(new_node->key_, key);
    new_node->value_ = value;

    if (buckets_[bucket] == nullptr) {
        buckets_[bucket] = new_node;
    } else {
        Node* cursor = buckets_[bucket];
        while (cursor->next_) {
            cursor = cursor->next_;
        }
        cursor->next_ = new_node;
    }
}

void extract_print_discard (
    Hashtable& hashtable,
    char* key
    )
{
    char itoa_buffer[33];
    int* value;
    value = static_cast<int*>(hashtable.remove(key));
    itoa(*value, itoa_buffer, 10);
    puts(itoa_buffer);
    puts("\n");
    delete[] value;
}

int main (
    )
{
    Hashtable h(8);

    h.put("wisconsin", new int[1]{7});
    h.put("indiana", new int[1]{4});
    h.put("ohio", new int[1]{2});
    h.put("illinois", new int[1]{1});

    extract_print_discard(h, "illinois");
    extract_print_discard(h, "ohio");
    extract_print_discard(h, "indiana");
    extract_print_discard(h, "wisconsin");

    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}
