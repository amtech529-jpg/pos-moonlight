from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal
from datetime import date, timedelta
from .models import Receivable

User = get_user_model()


class ReceivableModelTest(TestCase):
    """Test cases for Receivable model"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            full_name='Test User'
        )
        
        self.receivable_data = {
            'debtor_name': 'John Doe',
            'debtor_phone': '+92-300-1234567',
            'amount_given': Decimal('10000.00'),
            'reason_or_item': 'Business loan for shop renovation',
            'date_lent': date.today(),
            'expected_return_date': date.today() + timedelta(days=30),
            'notes': 'Monthly installments of 5000 PKR',
            'created_by': self.user
        }
    
    def test_create_receivable(self):
        """Test creating a receivable"""
        receivable = Receivable.objects.create(**self.receivable_data)
        
        self.assertEqual(receivable.debtor_name, 'John Doe')
        self.assertEqual(receivable.amount_given, Decimal('10000.00'))
        self.assertEqual(receivable.balance_remaining, Decimal('10000.00'))
        self.assertTrue(receivable.is_active)
        self.assertEqual(receivable.created_by, self.user)
    
    def test_balance_calculation(self):
        """Test automatic balance calculation"""
        receivable = Receivable.objects.create(**self.receivable_data)
        
        # Initial balance should equal amount given
        self.assertEqual(receivable.balance_remaining, receivable.amount_given)
        
        # Record a payment
        receivable.record_payment(Decimal('3000.00'))
        self.assertEqual(receivable.balance_remaining, Decimal('7000.00'))
        self.assertEqual(receivable.amount_returned, Decimal('3000.00'))
    
    def test_validation_amount_returned(self):
        """Test validation that amount returned cannot exceed amount given"""
        receivable = Receivable.objects.create(**self.receivable_data)
        
        with self.assertRaises(ValidationError):
            receivable.record_payment(Decimal('15000.00'))
    
    def test_validation_expected_return_date(self):
        """Test validation that expected return date cannot be before date lent"""
        invalid_data = self.receivable_data.copy()
        invalid_data['expected_return_date'] = date.today() - timedelta(days=1)
        
        with self.assertRaises(ValidationError):
            Receivable.objects.create(**invalid_data)
    
    def test_is_overdue(self):
        """Test overdue calculation"""
        # Create overdue receivable
        overdue_data = self.receivable_data.copy()
        overdue_data['expected_return_date'] = date.today() - timedelta(days=5)
        overdue_receivable = Receivable.objects.create(**overdue_data)
        
        self.assertTrue(overdue_receivable.is_overdue())
        self.assertEqual(overdue_receivable.days_overdue(), 5)
        
        # Create non-overdue receivable
        non_overdue_data = self.receivable_data.copy()
        non_overdue_data['expected_return_date'] = date.today() + timedelta(days=5)
        non_overdue_receivable = Receivable.objects.create(**non_overdue_data)
        
        self.assertFalse(non_overdue_receivable.is_overdue())
        self.assertEqual(non_overdue_receivable.days_overdue(), 0)
    
    def test_payment_status(self):
        """Test payment status methods"""
        receivable = Receivable.objects.create(**self.receivable_data)
        
        # Initially unpaid
        self.assertTrue(receivable.is_partially_paid())
        self.assertFalse(receivable.is_fully_paid())
        
        # Partially paid
        receivable.record_payment(Decimal('5000.00'))
        self.assertTrue(receivable.is_partially_paid())
        self.assertFalse(receivable.is_fully_paid())
        
        # Fully paid
        receivable.record_payment(Decimal('5000.00'))
        self.assertFalse(receivable.is_partially_paid())
        self.assertTrue(receivable.is_fully_paid())
    
    def test_soft_delete(self):
        """Test soft deletion"""
        receivable = Receivable.objects.create(**self.receivable_data)
        
        receivable.soft_delete()
        self.assertFalse(receivable.is_active)
        
        receivable.restore()
        self.assertTrue(receivable.is_active)
    
    def test_str_representation(self):
        """Test string representation"""
        receivable = Receivable.objects.create(**self.receivable_data)
        expected_str = f"John Doe - 10000.00 PKR ({date.today()})"
        self.assertEqual(str(receivable), expected_str)


class ReceivableQuerySetTest(TestCase):
    """Test cases for Receivable QuerySet methods"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            full_name='Test User'
        )
        
        # Create test receivables
        self.receivable1 = Receivable.objects.create(
            debtor_name='Alice Smith',
            debtor_phone='+92-300-1111111',
            amount_given=Decimal('5000.00'),
            reason_or_item='Personal loan',
            date_lent=date.today() - timedelta(days=10),
            expected_return_date=date.today() - timedelta(days=5),  # Overdue
            created_by=self.user
        )
        
        self.receivable2 = Receivable.objects.create(
            debtor_name='Bob Johnson',
            debtor_phone='+92-300-2222222',
            amount_given=Decimal('8000.00'),
            reason_or_item='Business loan',
            date_lent=date.today(),
            expected_return_date=date.today() + timedelta(days=7),
            created_by=self.user
        )
        
        self.receivable3 = Receivable.objects.create(
            debtor_name='Carol Brown',
            debtor_phone='+92-300-3333333',
            amount_given=Decimal('3000.00'),
            reason_or_item='Emergency loan',
            date_lent=date.today() - timedelta(days=20),
            expected_return_date=date.today() - timedelta(days=15),
            created_by=self.user
        )
        
        # Make one fully paid
        self.receivable3.record_payment(Decimal('3000.00'))
    
    def test_active_receivables(self):
        """Test active receivables filter"""
        active_count = Receivable.active_receivables().count()
        self.assertEqual(active_count, 3)
        
        # Soft delete one
        self.receivable1.soft_delete()
        active_count = Receivable.active_receivables().count()
        self.assertEqual(active_count, 2)
    
    def test_overdue_receivables(self):
        """Test overdue receivables filter"""
        overdue_count = Receivable.objects.overdue().count()
        self.assertEqual(overdue_count, 2)  # receivable1 and receivable3
    
    def test_due_today(self):
        """Test due today filter"""
        # Set one to be due today
        self.receivable2.expected_return_date = date.today()
        self.receivable2.save()
        
        due_today_count = Receivable.objects.due_today().count()
        self.assertEqual(due_today_count, 1)
    
    def test_fully_paid(self):
        """Test fully paid filter"""
        fully_paid_count = Receivable.objects.fully_paid().count()
        self.assertEqual(fully_paid_count, 1)  # receivable3
    
    def test_search(self):
        """Test search functionality"""
        # Search by debtor name
        search_results = Receivable.objects.search('Alice')
        self.assertEqual(search_results.count(), 1)
        self.assertEqual(search_results.first(), self.receivable1)
        
        # Search by phone
        search_results = Receivable.objects.search('2222222')
        self.assertEqual(search_results.count(), 1)
        self.assertEqual(search_results.first(), self.receivable2)
    
    def test_amount_range(self):
        """Test amount range filter"""
        # Filter by minimum amount
        min_amount_results = Receivable.objects.amount_range(min_amount=5000)
        self.assertEqual(min_amount_results.count(), 2)  # receivable1 and receivable2
        
        # Filter by maximum amount
        max_amount_results = Receivable.objects.amount_range(max_amount=5000)
        self.assertEqual(max_amount_results.count(), 2)  # receivable1 and receivable3


class ReceivableClassMethodsTest(TestCase):
    """Test cases for Receivable class methods"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            full_name='Test User'
        )
        
        # Create test receivables
        Receivable.objects.create(
            debtor_name='Test User 1',
            debtor_phone='+92-300-1111111',
            amount_given=Decimal('1000.00'),
            reason_or_item='Test loan 1',
            created_by=self.user
        )
        
        Receivable.objects.create(
            debtor_name='Test User 2',
            debtor_phone='+92-300-2222222',
            amount_given=Decimal('2000.00'),
            reason_or_item='Test loan 2',
            created_by=self.user
        )
    
    def test_total_outstanding(self):
        """Test total outstanding calculation"""
        total_outstanding = Receivable.total_outstanding()
        self.assertEqual(total_outstanding, Decimal('3000.00'))
    
    def test_overdue_receivables(self):
        """Test overdue receivables class method"""
        overdue_count = Receivable.overdue_receivables().count()
        self.assertEqual(overdue_count, 0)  # No overdue receivables in this test


# Additional test classes can be added for:
# - Serializer tests
# - View tests
# - API endpoint tests
# - Permission tests
# - Integration tests
