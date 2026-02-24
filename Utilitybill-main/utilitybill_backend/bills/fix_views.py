#!/usr/bin/env python
"""Fix and extend views.py with review endpoints"""

import re

# Read the file
with open('views.py', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# Find where delete_notification_old is defined and truncate there
pattern = r'(@api_view\(\[\'POST\'\]\)\s*@permission_classes\(\[AllowAny\]\)\s*@csrf_exempt\s*def delete_notification_old\(request\):\s*"""Delete a notification[^"]*""")'

match = re.search(pattern, content, re.DOTALL)
if match:
    # Truncate content at the end of this function definition
    end_pos = match.end()
    # Find the end of the docstring
    content = content[:end_pos] + '\n    pass\n\n\n# ==================== REVIEW ENDPOINTS ====================\n'
else:
    # Just append at the end
    content = content.rstrip() + '\n\n# ==================== REVIEW ENDPOINTS ====================\n'

# Add review endpoints
review_endpoints = '''
@api_view(['POST'])
@permission_classes([AllowAny])
@csrf_exempt
def add_review(request):
    """Add a new review (unauthenticated endpoint for mobile app)"""
    try:
        provider_name = (request.data.get('provider_name') or '').strip()
        utility_type = (request.data.get('utility_type') or '').strip()
        rating = request.data.get('rating')
        message = (request.data.get('message') or '').strip()
        username = (request.data.get('username') or '').strip()
        
        # Validate required fields
        if not all([provider_name, utility_type, rating, message]):
            return Response({
                'error': 'provider_name, utility_type, rating, and message are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate rating
        try:
            rating = int(rating)
            if rating < 1 or rating > 5:
                return Response({
                    'error': 'Rating must be between 1 and 5'
                }, status=status.HTTP_400_BAD_REQUEST)
        except (ValueError, TypeError):
            return Response({
                'error': 'Rating must be an integer'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get user if username is provided
        user = None
        if username:
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist:
                pass
        
        # Create review
        review = Review.objects.create(
            user=user,
            provider_name=provider_name,
            utility_type=utility_type,
            rating=rating,
            message=message
        )
        
        serializer = ReviewSerializer(review)
        return Response({
            'success': True,
            'message': 'Review created successfully',
            'review': serializer.data
        }, status=status.HTTP_201_CREATED)
    
    except Exception as e:
        print(f"[REVIEW ERROR] {e}")
        return Response({
            'error': f'Failed to create review: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
@csrf_exempt
def list_reviews(request):
    """List reviews by provider or utility type"""
    try:
        provider_name = (request.query_params.get('provider_name') or '').strip()
        utility_type = (request.query_params.get('utility_type') or '').strip()
        
        # Build query
        query = Review.objects.all()
        
        if provider_name:
            query = query.filter(provider_name__iexact=provider_name)
        
        if utility_type:
            query = query.filter(utility_type__iexact=utility_type)
        
        # Order by created_at descending
        query = query.order_by('-created_at')
        
        serializer = ReviewSerializer(query, many=True)
        return Response({
            'success': True,
            'count': query.count(),
            'reviews': serializer.data
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"[REVIEW LIST ERROR] {e}")
        return Response({
            'error': f'Failed to fetch reviews: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([AllowAny])
@csrf_exempt
def review_stats(request):
    """Get review statistics for a provider"""
    try:
        provider_name = (request.query_params.get('provider_name') or '').strip()
        utility_type = (request.query_params.get('utility_type') or '').strip()
        
        if not provider_name and not utility_type:
            return Response({
                'error': 'provider_name or utility_type is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Build query
        query = Review.objects.all()
        
        if provider_name:
            query = query.filter(provider_name__iexact=provider_name)
        
        if utility_type:
            query = query.filter(utility_type__iexact=utility_type)
        
        # Calculate stats
        total_reviews = query.count()
        avg_rating = 0
        rating_distribution = {
            1: query.filter(rating=1).count(),
            2: query.filter(rating=2).count(),
            3: query.filter(rating=3).count(),
            4: query.filter(rating=4).count(),
            5: query.filter(rating=5).count(),
        }
        
        if total_reviews > 0:
            from django.db.models import Avg
            avg_rating = float(query.aggregate(Avg('rating'))['rating__avg'] or 0)
        
        return Response({
            'success': True,
            'total_reviews': total_reviews,
            'average_rating': round(avg_rating, 2),
            'rating_distribution': rating_distribution
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(f"[REVIEW STATS ERROR] {e}")
        return Response({
            'error': f'Failed to fetch stats: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)
'''

content += review_endpoints

# Write back
with open('views.py', 'w', encoding='utf-8') as f:
    f.write(content)

print("✓ views.py cleaned and review endpoints added")
