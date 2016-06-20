#include "userlib"
#include "hashtable.h"


Hashtable::Hashtable (
    int buckets_count
    ) : buckets_count_(buckets_count)
{
    buckets_ = new Node*[buckets_count]();
}

Hashtable::~Hashtable (
    )
{
    if (buckets_) {
        delete_buckets(buckets_, buckets_count_);
        delete[] buckets_;
    }
}

Hashtable::Hashtable (
    const Hashtable& other
    ) : buckets_count_(other.buckets_count_)
{
    buckets_ = new Node*[other.buckets_count_]();
    deep_copy_from_buckets(other.buckets_, other.buckets_count_);
}

Hashtable& Hashtable::operator= (
    const Hashtable& other
    )
{
    if (&other == this) {
        return *this;
    }

    if (buckets_ != nullptr) {
        delete_buckets(buckets_, buckets_count_);
    }

    buckets_ = new Node*[other.buckets_count_]();
    buckets_count_ = other.buckets_count_;

    deep_copy_from_buckets(other.buckets_, other.buckets_count_);

    return *this;
}

int Hashtable::hash (
    char* key
    )
{
    int hash_value = 0;
    while (*key != 0) {
        hash_value = (31 * hash_value + *key) % buckets_count_;
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

void Hashtable::deep_copy_from_buckets (
    Node** buckets_from,
    int buckets_from_count
    )
{
    // In this particular implementation, the values
    // being stored in the table are void*; because
    // we don't know what those objects are, and
    // don't own their lifetimes, this "deep copy"
    // will still result in multiple hash tables
    // pointing to the same objects. So we need to
    // be careful!
    for (int i = 0; i < buckets_from_count; i++) {
        Node* cursor = buckets_from[i];
        while (cursor) {
            // Insert it into the new table
            put(cursor->key_, cursor->value_);
            cursor = cursor->next_;
        }
    }
}

void Hashtable::delete_buckets (
    Node** buckets,
    int buckets_count
    )
{
    for (int i = 0; i < buckets_count; i++) {
        Node* current = buckets[i];
        Node* next = nullptr;
        while (current) {
            next = current->next_;
            delete[] current->key_;
            delete current;
            current = next;
        }
    }
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

void Hashtable::resize (
    int new_size
    )
{
    if (new_size == buckets_count_) {
        return;
    }

    Node** new_buckets = new Node*[new_size]();

    // Stash the old pointers
    Node** old_buckets = buckets_;
    int old_buckets_count = buckets_count_;

    buckets_ = new_buckets;
    buckets_count_ = new_size;

    // Copy the buckets over
    deep_copy_from_buckets(old_buckets, old_buckets_count);

    // Delete the old lists
    delete_buckets(old_buckets, old_buckets_count);
    delete[] old_buckets;
}

void extract_print_discard (
    Hashtable& hashtable,
    char* key
    )
{
    int* value = static_cast<int*>(hashtable.remove(key));
    printf("%d\n", *value);
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

    Hashtable i(h);
    i.resize(1);
    i.resize(64);

    Hashtable j = i;

    extract_print_discard(j, "illinois");
    extract_print_discard(j, "ohio");
    extract_print_discard(j, "indiana");
    extract_print_discard(j, "wisconsin");

    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}