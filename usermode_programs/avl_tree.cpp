#include "userlib"
#include "avl_tree.h"


Node::Node (
    int value
    ) : left_(nullptr), right_(nullptr),
        value_(value), height_(1), count_(1)
{
}

void Node::updateHeightAndCount (
    )
{
    int left_height = left_ ? left_->height_ : 0;
    int right_height = right_ ? right_->height_ : 0;
    height_ = MAX(left_height, right_height) + 1;

    int left_count = left_ ? left_->count_ : 0;
    int right_count = right_ ? right_->count_ : 0;
    count_ = left_count + right_count + 1;
}

int Node::balanceFactor (
    )
{
    int left_height = left_ ? left_->height_ : 0;
    int right_height = right_ ? right_->height_ : 0;
    return left_height - right_height;
}

Node* Node::rebalance (
    )
{
    updateHeightAndCount();

    int parent_balance_factor = balanceFactor();
    int child_balance_factor;
    Node* new_root = this;

    assert(parent_balance_factor >= -2 && parent_balance_factor <= 2);

    if (parent_balance_factor >= -1 && parent_balance_factor <= 1) {
        // Nothing to do, just return the root
        return new_root;
    }

    if (parent_balance_factor == -2) {
        // Tree is right-heavy
        child_balance_factor = right_->balanceFactor();
        if (child_balance_factor == 1) {
            // Rotate right through child
            right_ = right_->rotateRight();
        }
        // Rotate left through us
        new_root = rotateLeft();
    } else {
        // Tree is left-heavy
        child_balance_factor = left_->balanceFactor();
        if (child_balance_factor == -1) {
            // Rotate left through child
            left_ = left_->rotateLeft();
        }
        // Rotate right through us
        new_root = rotateRight();
    }

    return new_root;
}

Node* Node::insert (
    Node* node
    )
{
    // We don't allow duplicate values right now
    assert(node->value_ != value_);

    if (node->value_ < value_) {
        // Go left
        if (left_) {
            left_ = left_->insert(node);
        } else {
            left_ = node;
        }
        return rebalance();
    }

    // Go right
    if (right_) {
        right_ = right_->insert(node);
    } else {
        right_ = node;
    }
    return rebalance();
}

Node* Node::extract (
    int value,
    Node** extracted
    )
{
    if (value < value_) {
        // Go left
        if (left_) {
            left_ = left_->extract(value, extracted);
        } else {
            *extracted = nullptr;
        }
        return rebalance();
    }

    if (value > value_) {
        // Go right
        if (right_) {
            right_ = right_->extract(value, extracted);
        } else {
            *extracted = nullptr;
        }
        return rebalance();
    }

    // We are the node to remove. Swap ourselves
    // with the in-order predecessor if there is
    // one, else just return the right subtree
    if (!left_) {
        Node* new_root = right_;
        *extracted = this;
        left_ = nullptr;
        right_ = nullptr;
        updateHeightAndCount();
        return new_root;
    }

    // Find the in-order predecessor and swap
    Node* predecessor;
    left_ = left_->extractMaximum(&predecessor);
    predecessor->left_ = left_;
    predecessor->right_ = right_;
    predecessor->updateHeightAndCount();

    *extracted = this;
    left_ = nullptr;
    right_ = nullptr;
    updateHeightAndCount();

    return predecessor->rebalance();
}

int Node::getValue (
    )
{
    return value_;
}

Node* Node::rotateLeft (
    )
{
    Node* new_root = right_;
    right_ = new_root->left_;
    new_root->left_ = this;

    // Update height and count from bottom up,
    // to fix the fact that we (old root) have
    // gone down a level
    updateHeightAndCount();
    new_root->updateHeightAndCount();

    return new_root;
}

Node* Node::rotateRight (
    )
{
    Node* new_root = left_;
    left_ = new_root->right_;
    new_root->right_ = this;

    // Update height and count from bottom up
    updateHeightAndCount();
    new_root->updateHeightAndCount();

    return new_root;
}

Node* Node::extractMaximum (
    Node** extracted
    )
{
    if (!right_) {
        // We are the max; pull ourselves out
        *extracted = this;
        return left_;
    }
    right_ = right_->extractMaximum(extracted);
    return rebalance();
}

int main (
    )
{
    char itoa_buffer[33];

    Node* root = new Node(0);
    for (int i = 1; i < 100; i++) {
        root = root->insert(new Node(i));
    }
    for (int i = 0; i < 50; i++) {
        Node* extracted;
        root = root->extract(i, &extracted);
        itoa(extracted->getValue(), itoa_buffer, 10);
        puts("extracted ");
        puts(itoa_buffer);
        puts("\n");
        delete extracted;
    }
    return 0;
}

extern "C" void _start (
    )
{
    _exit(main());
}