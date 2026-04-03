from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from decimal import Decimal
from datetime import date
from .models import Payment
from labors.models import Labor
from vendors.models import Vendor
from orders.models import Order
from sales.models import Sales
from customers.models import Customer
from categories.models import Category
from products.models import Product

User = get_user_model()


class PaymentModelTest(TestCase):
    """Test cases for Payment model"""
    
    def setUp(self):
        """Set up test data"""
        # Create test user
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            full_name='Test User'
        )
        
        # Create test category
        self.category = Category.objects.create(
            name='Test Category',
            description='Test category description',
            created_by=self.user
        )
        
        # Create test customer
        self.customer = Customer.objects.create(
            name='Test Customer',
            phone='+92-300-1234567',
            email='customer@example.com',
            created_by=self.user
        )
        
        # Create test product
        self.product = Product.objects.create(
            name='Test Product',
            detail='Test product detail',
            price=Decimal('1000.00'),
            color='Red',
            fabric='Cotton',
            pieces=['Shirt'],
            quantity=10,
            category=self.category,
            created_by=self.user
        )
        
        # Create test labor
        self.labor = Labor.objects.create(
            name='Test Labor',
            cnic='12345-1234567-1',
            phone_number='+92-300-1234567',
            city='Test City',
            area='Test Area',
            designation='Tailor',
            joining_date=date.today(),
            salary=Decimal('15000.00'),
            created_by=self.user
        )
        
        # Create test vendor
        self.vendor = Vendor.objects.create(
            name='Test Vendor',
            business_name='Test Business',
            cnic='12345-1234567-2',
            phone='+92-300-1234568',
            city='Test City',
            area='Test Area',
            created_by=self.user
        )
        
        # Create test order
        self.order = Order.objects.create(
            customer=self.customer,
            customer_name=self.customer.name,
            customer_phone=self.customer.phone,
            customer_email=self.customer.email,
            advance_payment=Decimal('500.00'),
            total_amount=Decimal('2000.00'),
            remaining_amount=Decimal('1500.00'),
            date_ordered=date.today(),
            expected_delivery_date=date.today(),
            description='Test order',
            created_by=self.user
        )
        
        # Create test sale
        self.sale = Sales.objects.create(
            customer=self.customer,
            customer_name=self.customer.name,
            customer_phone=self.customer.phone,
            customer_email=self.customer.email,
            subtotal=Decimal('1000.00'),
            overall_discount=Decimal('0.00'),
            gst_percentage=Decimal('17.00'),
            tax_amount=Decimal('170.00'),
            grand_total=Decimal('1170.00'),
            amount_paid=Decimal('1170.00'),
            remaining_amount=Decimal('0.00'),
            is_fully_paid=True,
            payment_method='CASH',
            date_of_sale=timezone.now(),
            status='PAID',
            created_by=self.user
        )
    
    def test_payment_creation(self):
        """Test payment creation"""
        payment = Payment.objects.create(
            labor=self.labor,
            amount_paid=Decimal('15000.00'),
            bonus=Decimal('1000.00'),
            deduction=Decimal('500.00'),
            payment_month=date.today(),
            is_final_payment=True,
            payment_method='BANK_TRANSFER',
            description='Monthly salary payment',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        self.assertEqual(payment.amount_paid, Decimal('15000.00'))
        self.assertEqual(payment.bonus, Decimal('1000.00'))
        self.assertEqual(payment.deduction, Decimal('500.00'))
        self.assertEqual(payment.payer_type, 'LABOR')
        self.assertEqual(payment.labor_name, self.labor.name)
        self.assertEqual(payment.labor_phone, self.labor.phone_number)
        self.assertEqual(payment.labor_role, self.labor.designation)
        self.assertTrue(payment.is_active)
    
    def test_payment_with_vendor(self):
        """Test payment creation with vendor"""
        payment = Payment.objects.create(
            vendor=self.vendor,
            amount_paid=Decimal('5000.00'),
            payment_month=date.today(),
            payment_method='CASH',
            description='Vendor payment',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        self.assertEqual(payment.payer_type, 'VENDOR')
        self.assertEqual(payment.payer_id, self.vendor.id)
    
    def test_payment_with_order(self):
        """Test payment creation with order"""
        payment = Payment.objects.create(
            order=self.order,
            amount_paid=Decimal('1000.00'),
            payment_month=date.today(),
            payment_method='CASH',
            description='Order payment',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        self.assertEqual(payment.payer_type, 'CUSTOMER')
        self.assertEqual(payment.payer_id, self.customer.id)
    
    def test_payment_with_sale(self):
        """Test payment creation with sale"""
        payment = Payment.objects.create(
            sale=self.sale,
            amount_paid=Decimal('1170.00'),
            payment_month=date.today(),
            payment_method='CASH',
            description='Sale payment',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        self.assertEqual(payment.payer_type, 'CUSTOMER')
        self.assertEqual(payment.payer_id, self.customer.id)
    
    def test_payment_validation(self):
        """Test payment validation"""
        # Test negative amount
        with self.assertRaises(Exception):
            Payment.objects.create(
                labor=self.labor,
                amount_paid=Decimal('-100.00'),
                payment_month=date.today(),
                payment_method='CASH',
                date=date.today(),
                time=timezone.now().time(),
                created_by=self.user
            )
        
        # Test negative bonus
        with self.assertRaises(Exception):
            Payment.objects.create(
                labor=self.labor,
                amount_paid=Decimal('1000.00'),
                bonus=Decimal('-100.00'),
                payment_month=date.today(),
                payment_method='CASH',
                date=date.today(),
                time=timezone.now().time(),
                created_by=self.user
            )
    
    def test_payment_properties(self):
        """Test payment properties"""
        payment = Payment.objects.create(
            labor=self.labor,
            amount_paid=Decimal('15000.00'),
            bonus=Decimal('1000.00'),
            deduction=Decimal('500.00'),
            payment_month=date.today(),
            payment_method='CASH',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        self.assertEqual(payment.net_amount, Decimal('15500.00'))
        self.assertTrue(payment.formatted_amount.startswith('PKR'))
        self.assertEqual(payment.payment_period_display, date.today().strftime('%B %Y'))
    
    def test_payment_methods(self):
        """Test payment methods"""
        payment = Payment.objects.create(
            labor=self.labor,
            amount_paid=Decimal('15000.00'),
            payment_month=date.today(),
            payment_method='CASH',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        # Test soft delete
        payment.soft_delete()
        self.assertFalse(payment.is_active)
        
        # Test restore
        payment.restore()
        self.assertTrue(payment.is_active)
        
        # Test mark as final
        payment.mark_as_final()
        self.assertTrue(payment.is_final_payment)
        
        # Test add bonus
        payment.add_bonus(Decimal('500.00'), 'Performance bonus')
        self.assertEqual(payment.bonus, Decimal('500.00'))
        
        # Test add deduction
        payment.add_deduction(Decimal('200.00'), 'Late deduction')
        self.assertEqual(payment.deduction, Decimal('200.00'))
    
    def test_payment_queryset_methods(self):
        """Test payment queryset methods"""
        # Create multiple payments
        Payment.objects.create(
            labor=self.labor,
            amount_paid=Decimal('15000.00'),
            payment_month=date.today(),
            payment_method='CASH',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        Payment.objects.create(
            vendor=self.vendor,
            amount_paid=Decimal('5000.00'),
            payment_month=date.today(),
            payment_method='BANK_TRANSFER',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        # Test active payments
        self.assertEqual(Payment.active_payments().count(), 2)
        
        # Test by payer type
        self.assertEqual(Payment.objects.by_payer_type('LABOR').count(), 1)
        self.assertEqual(Payment.objects.by_payer_type('VENDOR').count(), 1)
        
        # Test by payment method
        self.assertEqual(Payment.objects.by_payment_method('CASH').count(), 1)
        self.assertEqual(Payment.objects.by_payment_method('BANK_TRANSFER').count(), 1)
        
        # Test search
        search_results = Payment.objects.search('Test Labor')
        self.assertEqual(search_results.count(), 1)
    
    def test_payment_statistics(self):
        """Test payment statistics"""
        # Create payments for statistics
        Payment.objects.create(
            labor=self.labor,
            amount_paid=Decimal('15000.00'),
            bonus=Decimal('1000.00'),
            deduction=Decimal('500.00'),
            payment_month=date.today(),
            payment_method='CASH',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        Payment.objects.create(
            vendor=self.vendor,
            amount_paid=Decimal('5000.00'),
            payment_month=date.today(),
            payment_method='BANK_TRANSFER',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        stats = Payment.get_statistics()
        
        self.assertEqual(stats['total_payments'], 2)
        self.assertEqual(stats['total_amount'], 20000.0)
        self.assertEqual(stats['total_bonus'], 1000.0)
        self.assertEqual(stats['total_deduction'], 500.0)
        self.assertEqual(stats['net_amount'], 20500.0)
        self.assertIn('labor', stats['payer_type_breakdown'])
        self.assertIn('vendor', stats['payer_type_breakdown'])


class PaymentSerializerTest(TestCase):
    """Test cases for Payment serializers"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            full_name='Test User'
        )
        
        self.labor = Labor.objects.create(
            name='Test Labor',
            cnic='12345-1234567-1',
            phone_number='+92-300-1234567',
            city='Test City',
            area='Test Area',
            designation='Tailor',
            joining_date=date.today(),
            salary=Decimal('15000.00'),
            created_by=self.user
        )
    
    def test_payment_serializer(self):
        """Test PaymentSerializer"""
        payment = Payment.objects.create(
            labor=self.labor,
            amount_paid=Decimal('15000.00'),
            payment_month=date.today(),
            payment_method='CASH',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
        
        serializer = PaymentSerializer(payment)
        data = serializer.data
        
        self.assertEqual(data['amount_paid'], '15000.00')
        self.assertEqual(data['payer_type'], 'LABOR')
        self.assertEqual(data['labor_name'], self.labor.name)
        self.assertEqual(data['labor_phone'], self.labor.phone_number)
        self.assertEqual(data['labor_role'], self.labor.designation)
    
    def test_payment_create_serializer(self):
        """Test PaymentCreateSerializer"""
        from .serializers import PaymentCreateSerializer
        
        data = {
            'labor': self.labor.id,
            'amount_paid': '15000.00',
            'payment_month': date.today(),
            'payment_method': 'CASH',
            'date': date.today(),
            'time': timezone.now().time()
        }
        
        serializer = PaymentCreateSerializer(
            data=data,
            context={'request': type('Request', (), {'user': self.user})()}
        )
        
        self.assertTrue(serializer.is_valid())
        payment = serializer.save()
        
        self.assertEqual(payment.amount_paid, Decimal('15000.00'))
        self.assertEqual(payment.created_by, self.user)


class PaymentViewTest(TestCase):
    """Test cases for Payment views"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            full_name='Test User'
        )
        
        self.labor = Labor.objects.create(
            name='Test Labor',
            cnic='12345-1234567-1',
            phone_number='+92-300-1234567',
            city='Test City',
            area='Test Area',
            designation='Tailor',
            joining_date=date.today(),
            salary=Decimal('15000.00'),
            created_by=self.user
        )
        
        self.payment = Payment.objects.create(
            labor=self.labor,
            amount_paid=Decimal('15000.00'),
            payment_month=date.today(),
            payment_method='CASH',
            date=date.today(),
            time=timezone.now().time(),
            created_by=self.user
        )
    
    def test_list_payments_view(self):
        """Test list payments view"""
        from django.test import Client
        from django.urls import reverse
        
        client = Client()
        client.force_login(self.user)
        
        response = client.get(reverse('payments:list_payments'))
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(len(data['data']['payments']), 1)
    
    def test_create_payment_view(self):
        """Test create payment view"""
        from django.test import Client
        from django.urls import reverse
        
        client = Client()
        client.force_login(self.user)
        
        data = {
            'labor': self.labor.id,
            'amount_paid': '20000.00',
            'payment_month': date.today(),
            'payment_method': 'BANK_TRANSFER',
            'date': date.today(),
            'time': timezone.now().time()
        }
        
        response = client.post(reverse('payments:create_payment'), data)
        self.assertEqual(response.status_code, 201)
        
        response_data = response.json()
        self.assertTrue(response_data['success'])
        self.assertEqual(Payment.objects.count(), 2)
    
    def test_get_payment_view(self):
        """Test get payment view"""
        from django.test import Client
        from django.urls import reverse
        
        client = Client()
        client.force_login(self.user)
        
        response = client.get(reverse('payments:get_payment', kwargs={'payment_id': self.payment.id}))
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertTrue(data['success'])
        self.assertEqual(data['data']['id'], str(self.payment.id))
