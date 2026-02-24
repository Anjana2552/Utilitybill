from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    UserProfile, UserUtility, GeneratedBill, UtilityBill, Payment, ChatMessage, Wallet, WalletTransaction, PaymentMethod, Notification, Review
)


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model"""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'is_active']
        read_only_fields = ['id', 'is_active']


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for UserProfile model"""
    user = UserSerializer(read_only=True)
    role_display = serializers.CharField(source='get_role_display', read_only=True)

    class Meta:
        model = UserProfile
        fields = ['id', 'user', 'full_name', 'email', 'role', 'role_display', 'phone', 'house_number', 'address', 'utility_type', 'created_at', 'updated_at']
        read_only_fields = ['id', 'role', 'created_at', 'updated_at']


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    password2 = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'}, label='Confirm Password')

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2', 'first_name', 'last_name']

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        # Create user profile with default 'user' role for all registrations
        full_name = f"{user.first_name} {user.last_name}".strip()
        UserProfile.objects.create(
            user=user,
            role='user',
            full_name=full_name,
            email=user.email,
        )
        return user


class UserUtilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = UserUtility
        fields = [
            'id', 'user', 'user_name', 'house_number', 'utility_type', 'provider_name',
            'consumer_number', 'water_connection_number', 'gas_connection_number',
            'wifi_consumer_id', 'dth_subscriber_id', 'meter_number',
            'connection_type', 'plan_name', 'is_active', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class GeneratedBillSerializer(serializers.ModelSerializer):
    class Meta:
        model = GeneratedBill
        fields = [
            'id', 'bill_id', 'utility_type', 'provider_name', 'consumer_name',
            'consumer_number', 'water_connection_number', 'gas_consumer_id',
            'wifi_consumer_id', 'dth_subscriber_id', 'plan_name', 'dth_package_name',
            'specified_utility_type', 'previous_reading', 'current_reading',
            'units_consumed', 'rate_per_unit', 'total_amount', 'reading_date',
            'due_date', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class UtilityBillSerializer(serializers.ModelSerializer):
    class Meta:
        model = UtilityBill
        fields = [
            'id', 'utility_type', 'bill_id', 'consumer_name', 'consumer_id',
            'previous_reading', 'current_reading', 'total_amount', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ['id', 'bill', 'amount', 'payment_date', 'payment_method', 'status']
        read_only_fields = ['id', 'payment_date']


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = [
            'id', 'user_name', 'provider_name', 'sender_role', 'sender_username',
            'text', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class WalletSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Wallet
        fields = ['id', 'user', 'balance', 'updated_at']
        read_only_fields = ['id', 'user', 'updated_at']


class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = ['id', 'amount', 'type', 'reason', 'payment', 'created_at']
        read_only_fields = ['id', 'created_at']

class PaymentMethodSerializer(serializers.ModelSerializer):
    """Serializer for PaymentMethod model"""
    class Meta:
        model = PaymentMethod
        fields = ['id', 'method', 'detail', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for Notification model"""
    class Meta:
        model = Notification
        fields = ['id', 'notification_type', 'title', 'message', 'utility_type', 'bill_id', 'due_date', 'read', 'created_at']
        read_only_fields = ['id', 'created_at']


class ReviewSerializer(serializers.ModelSerializer):
    """Serializer for Review model"""
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = Review
        fields = ['id', 'username', 'provider_name', 'utility_type', 'rating', 'message', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']