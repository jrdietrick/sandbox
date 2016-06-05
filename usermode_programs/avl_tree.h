#ifndef __AVL_TREE_H__
#define __AVL_TREE_H__

#define MAX(a, b) ((b) > (a) ? (b) : (a))

typedef class Node {

    Node* left_;
    Node* right_;
    int value_;
    int height_;
    int count_;

    void updateHeightAndCount (
        );

    int balanceFactor (
        );

    Node* rebalance (
        );

    Node* rotateLeft (
        );

    Node* rotateRight (
        );

    Node* extractMaximum (
        Node** extracted
        );

public:
    Node (
        int value
        );

    Node* insert (
        Node* node
        );

    Node* extract (
        int value,
        Node** extracted
        );

    int getValue (
        );

} Node;

#endif