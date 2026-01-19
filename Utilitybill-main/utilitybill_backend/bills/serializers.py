from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile, UserUtility, GeneratedBill, UtilityBill


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model"""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for UserProfile model"""
    user = UserSerializer(read_only=True)
    role_display = serializers.CharField(source='get_role_display', read_only=True)

    class Meta:
        model = UserProfile
        fields = ['id', 'user', 'full_name', 'email', 'role', 'role_display', 'phone', 'address', 'created_at', 'updated_at']
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
            'id', 'user', 'user_name', 'utility_type', 'provider_name',
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
