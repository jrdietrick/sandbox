#ifndef __HASHTABLE_H__
#define __HASHTABLE_H__

#define DEFAULT_BUCKET_COUNT 8

typedef class Hashtable {

    typedef struct Node {
        Node* next_;
        char* key_;
        void* value_;
    } Node;

    Node** buckets_;
    int buckets_count_;

    int hash (
        char* key
        );

    void* get_or_remove (
        char* key,
        bool delete_when_found
        );

    void deep_copy_from_buckets (
        Node** buckets_from,
        int buckets_from_count
        );

    static void delete_buckets (
        Node** buckets,
        int buckets_count
        );

public:
    Hashtable (
        int buckets_count
        );

    ~Hashtable (
        );

    Hashtable (
        const Hashtable& other
        );

    Hashtable& operator= (
        const Hashtable& other
        );

    bool contains (
        char* key
        );

    void* get (
        char* key
        );

    void* remove (
        char* key
        );

    void put (
        char* key,
        void* value
        );

    void resize (
        int new_size
        );

} Hashtable;

#endif
