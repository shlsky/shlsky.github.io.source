---
title: 深入分析Spring AOP机制
date: 2019-02-03 14:50:33
Tags: spring
---

## AOP代理方式

**Jdk动态代理**

**Cglib**

**静态代理**

**类加载代理**

## Jdk 动态代理

Jdk动态代理的核心是proxy.newProxyInstance(ClassLoader loader,Class<?>[] interfaces,InvocationHandler h)方法。

```java
IDrive proxyInstance = (IDrive) Proxy.newProxyInstance(handler.getClass().getClassLoader(), drive.getClass().getInterfaces(), handler);
```

```java
package com.java.aop.jdkproxy;

import sun.misc.ProxyGenerator;
import java.io.FileOutputStream;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/**
 * @author shl.sky
 * @date 2017/10/3
 */
public class JdkDynamicProxyTest {
	
	public static void main(String[] args) {
		IDrive drive = new DriveImpl();
		InvocationHandler handler = new DynamicProxy(drive);
		IDrive proxyInstance = (IDrive) Proxy.newProxyInstance(handler.getClass().getClassLoader(), drive.getClass().getInterfaces(), handler);
		
		byte[] classFile = ProxyGenerator.generateProxyClass("$Proxy0", new Class[]{IDrive.class});
		
		//打印代理类
		try (FileOutputStream fos = new FileOutputStream("./IDriveProxy.class")) {
			fos.write(classFile);
			fos.flush();
			System.out.println("代理类class文件写入成功");
		} catch (Exception e) {
			System.out.println("写文件错误");
		}
		proxyInstance.doIt();
		
		
	}
	
	/**
	 * 接口
	 */
	public interface IDrive {
		
		/**
		 * 开车
		 */
		void doIt();
	}
	
	/**
	 * 被代理类
	 */
	public static class DriveImpl implements IDrive {
		@Override
		public void doIt() {
			System.out.println("drive car~");
		}
	}
	
	/**
	 * 代理handler
	 */
	public static class DynamicProxy implements InvocationHandler {
		/**
		 * 这个就是我们要代理的真实对象
		 */
		private Object real;
		
		/**
		 * 构造方法，给我们要代理的真实对象赋初值
		 */
		public DynamicProxy(Object real) {
			this.real = real;
		}
		
		@Override
		public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
			//在代理真实对象前我们可以添加一些自己的操作
			System.out.println("before rent house");
			
			System.out.println("Method:" + method);
			
			//当代理对象调用真实对象的方法时，其会自动的跳转到代理对象关联的handler对象的invoke方法来进行调用
			Object res = method.invoke(real, args);
			
			//在代理真实对象后我们也可以添加一些自己的操作
			System.out.println("after rent house");
			
			return res;
		}
	}
}
```

```
public static Object newProxyInstance(ClassLoader loader,
                                      Class<?>[] interfaces,
                                      InvocationHandler h)
    throws IllegalArgumentException
{
    Objects.requireNonNull(h);

    final Class<?>[] intfs = interfaces.clone();
    final SecurityManager sm = System.getSecurityManager();
    if (sm != null) {
        checkProxyAccess(Reflection.getCallerClass(), loader, intfs);
    }

    /*
     * Look up or generate the designated proxy class.
     * 这句话是重点
     */
    Class<?> cl = getProxyClass0(loader, intfs);
```



我们来看一下IDriveProxy.class，这是Proxy的子类反编译出来代码：

```java
//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

import com.java.aop.jdkproxy.JdkDynamicProxyTest.IDrive;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.lang.reflect.UndeclaredThrowableException;

public final class $Proxy0 extends Proxy implements IDrive {
    private static Method m1;
    private static Method m3;
    private static Method m2;
    private static Method m0;

    public $Proxy0(InvocationHandler var1) throws  {
        super(var1);
    }

    public final boolean equals(Object var1) throws  {
        try {
            return (Boolean)super.h.invoke(this, m1, new Object[]{var1});
        } catch (RuntimeException | Error var3) {
            throw var3;
        } catch (Throwable var4) {
            throw new UndeclaredThrowableException(var4);
        }
    }

    public final void doIt() throws  {
        try {
            //这里我们可以看到调用的正是：InvocationHandler.invoke(Object proxy, Method method, Object[] args)方法。
            super.h.invoke(this, m3, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final String toString() throws  {
        try {
            return (String)super.h.invoke(this, m2, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final int hashCode() throws  {
        try {
            return (Integer)super.h.invoke(this, m0, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    static {
        try {
            m1 = Class.forName("java.lang.Object").getMethod("equals", Class.forName("java.lang.Object"));
            m3 = Class.forName("com.java.aop.jdkproxy.JdkDynamicProxyTest$IDrive").getMethod("doIt");
            m2 = Class.forName("java.lang.Object").getMethod("toString");
            m0 = Class.forName("java.lang.Object").getMethod("hashCode");
        } catch (NoSuchMethodException var2) {
            throw new NoSuchMethodError(var2.getMessage());
        } catch (ClassNotFoundException var3) {
            throw new NoClassDefFoundError(var3.getMessage());
        }
    }
}

```



## Cglib 代理机制

```java
package com.java.aop.cglib;

import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;

import java.lang.reflect.Method;

/**
 * @author jackson
 * @date 16/2/19
 */
public class CglibAopTest {
	
	public static void main(String[] args) {
		CglibProxy proxy = new CglibProxy();
		// 通过生成子类的方式创建代理类，子类织入逻辑后调用super.method，
		// 如果super.method中调用了原类中其他方法，则通过JVM动态分派机制派给子类
		SayHello proxyImp = (SayHello) proxy.getProxy(SayHello.class);
		
		proxyImp.say();
	}
	
	public static class CglibProxy {
		
		private Enhancer enhancer = new Enhancer();
		
		public Object getProxy(Class clazz) {
			//设置需要创建子类的类
			enhancer.setSuperclass(clazz);
			enhancer.setCallback(new ProxyCallback());
			//通过字节码技术动态创建子类实例
			return enhancer.create();
		}
	}
	
	public static class ProxyCallback implements MethodInterceptor {
		
		@Override
		public Object intercept(Object cglibProxyObject, Method originMethod, Object[] args, MethodProxy methodProxy) throws Throwable {
			System.out.println("前置代理" + methodProxy.getSignature().toString());
			
			//通过代理类调用父类中的方法
			//此处不能用proxy.invoke的原因是MethodProxy.FastClassInfo.f1 对自己的递归调用,所以要使用invokeSuper调用父类的方法
			Object result = methodProxy.invokeSuper(cglibProxyObject, args);
			System.out.println("后置代理");
			return result;
		}
	}
	
	public static class SayHello {
		
		public void say() {
			System.out.println("say" + this.getClass());
			say1();
		}
		
		public void say1() {
			System.out.println("say1" + this.getClass());
		}
	}
}

```



## spring aop实现方式

spring aop有两种实现机制，分别是java动态代理和CGlib机制。Spring默认采取的动态代理机制实现AOP，当动态代理不可用时（代理类无接口）会使用CGlib机制

```java
/**
 * Enumeration used to determine whether JDK proxy-based or AspectJ weaving-based advice
 * should be applied.
 */
public enum AdviceMode {
    /**
     * 动态代理
     */
	PROXY,
    /**
     * cglib
     */
	ASPECTJ
}
```

### spring aop cglib实现方式

对照上面提到的Cglib代理机制，我们来通过代码梳理一下spring aop框架cglib代理的实现机制

@EnableAspectJAutoProxy(proxyTargetClass = true) 开启使用cglib代理模式

spring aop cglib实现的主要实现逻辑都在CglibAopProxy这类中。

```
@Override
public Object getProxy(ClassLoader classLoader) {
 
   try {
      ....

      // Configure CGLIB Enhancer...
      Enhancer enhancer = createEnhancer();
      ....
      enhancer.setSuperclass(proxySuperClass);
      enhancer.setInterfaces(AopProxyUtils.completeProxiedInterfaces(this.advised));
      enhancer.setNamingPolicy(SpringNamingPolicy.INSTANCE);
      enhancer.setStrategy(new ClassLoaderAwareUndeclaredThrowableStrategy(classLoader));
	  // 这里生成了cglib 回调子类 190行
      Callback[] callbacks = getCallbacks(rootClass);
      // fixedInterceptorMap only populated at this point, after getCallbacks call above
      //设置callback filter。
	  enhancer.setCallbackFilter(new 			ProxyCallbackFilter(this.advised.getConfigurationOnlyCopy(), this.fixedInterceptorMap, this.fixedInterceptorOffset));
			enhancer.setCallbackTypes(types);
      ...
      return createProxyClassAndInstance(enhancer, callbacks);
   }
   ...
}
```



我们继续分析getCallbacks(rootClass)的逻辑：

```
private Callback[] getCallbacks(Class<?> rootClass) throws Exception {
   // Parameters used for optimization choices...
   boolean exposeProxy = this.advised.isExposeProxy();
   boolean isFrozen = this.advised.isFrozen();
   boolean isStatic = this.advised.getTargetSource().isStatic();

   // Choose an "aop" interceptor (used for AOP calls).
   //这个是被代理的方法或类的intercept
   Callback aopInterceptor = new DynamicAdvisedInterceptor(this.advised);

   // Choose a "straight to target" interceptor. (used for calls that are
   // unadvised but can return this). May be required to expose the proxy.
   //这是未被代理的intercept
   Callback targetInterceptor;
   if (exposeProxy) {
      targetInterceptor = isStatic ?
            new StaticUnadvisedExposedInterceptor(this.advised.getTargetSource().getTarget()) :
            new DynamicUnadvisedExposedInterceptor(this.advised.getTargetSource());
   }
   else {
      targetInterceptor = isStatic ?
            new StaticUnadvisedInterceptor(this.advised.getTargetSource().getTarget()) :
            new DynamicUnadvisedInterceptor(this.advised.getTargetSource());
   }

   // Choose a "direct to target" dispatcher (used for
   // unadvised calls to static targets that cannot return this).
   Callback targetDispatcher = isStatic ?
         new StaticDispatcher(this.advised.getTargetSource().getTarget()) : new SerializableNoOp();

   Callback[] mainCallbacks = new Callback[] {
         aopInterceptor,  // for normal advice
         targetInterceptor,  // invoke target without considering advice, if optimized
         new SerializableNoOp(),  // no override for methods mapped to this
         targetDispatcher, this.advisedDispatcher,
         new EqualsInterceptor(this.advised),
         new HashCodeInterceptor(this.advised)
   };

   ...
   return callbacks;
}
```

我们看到被代理的方法或类，使用的是 DynamicAdvisedInterceptor(this.advised);

我们继续分析DynamicAdvisedInterceptor类：

```
/**
 * General purpose AOP callback. Used when the target is dynamic or when the
 * proxy is not frozen.
 */
private static class DynamicAdvisedInterceptor implements MethodInterceptor, Serializable {
	....

   @Override
   public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
      Object oldProxy = null;
      boolean setProxyContext = false;
      Class<?> targetClass = null;
      Object target = null;
      try {
         ...
         List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
         Object retVal;
         // Check whether we only have one InvokerInterceptor: that is,
         // no real advice, but just reflective invocation of the target.
         if (chain.isEmpty() && Modifier.isPublic(method.getModifiers())) {
            ...
         }
         else {
            // We need to create a method invocation...
            //把代理类和切面组合，然后执行
            retVal = new CglibMethodInvocation(proxy, target, method, args, targetClass, chain, methodProxy).proceed();
         }
         ...
      }
     ...
   }
```

我们看一下CglibMethodInvocation的实现

```
/**
 * Implementation of AOP Alliance MethodInvocation used by this AOP proxy.
 */
private static class CglibMethodInvocation extends ReflectiveMethodInvocation {

   private final MethodProxy methodProxy;

   private final boolean publicMethod;

   public CglibMethodInvocation(Object proxy, Object target, Method method, Object[] arguments,
         Class<?> targetClass, List<Object> interceptorsAndDynamicMethodMatchers, MethodProxy methodProxy) {

      super(proxy, target, method, arguments, targetClass, interceptorsAndDynamicMethodMatchers);
      this.methodProxy = methodProxy;
      this.publicMethod = Modifier.isPublic(method.getModifiers());
   }

   /**
    * Gives a marginal performance improvement versus using reflection to
    * invoke the target when invoking public methods.
    */
   @Override
   protected Object invokeJoinpoint() throws Throwable {
      if (this.publicMethod) {
         //一路追根溯源，基类执行了切面逻辑，然后调用子类的我们再此处发现methodProxy执行了target类的方法
         return this.methodProxy.invoke(this.target, this.arguments);
      }
      else {
         return super.invokeJoinpoint();
      }
   }
}
```



我们看一下 增强织入的逻辑：

```
public class ReflectiveMethodInvocation implements ProxyMethodInvocation, Cloneable {
	@Override
	public Object proceed() throws Throwable {
		//	We start with an index of -1 and increment early.
		if (this.currentInterceptorIndex == this.interceptorsAndDynamicMethodMatchers.size() - 1) {
			return invokeJoinpoint();
		}

		Object interceptorOrInterceptionAdvice =
				this.interceptorsAndDynamicMethodMatchers.get(++this.currentInterceptorIndex);
		if (interceptorOrInterceptionAdvice instanceof InterceptorAndDynamicMethodMatcher) {
			// Evaluate dynamic method matcher here: static part will already have
			// been evaluated and found to match.
			InterceptorAndDynamicMethodMatcher dm =
					(InterceptorAndDynamicMethodMatcher) interceptorOrInterceptionAdvice;
			if (dm.methodMatcher.matches(this.method, this.targetClass, this.arguments)) {
				
				//此处将 ReflectiveMethodInvocation 传给编织器，编织器在做增强后会回调ReflectiveMethodInvocation
				
				return dm.interceptor.invoke(this);
			}
			else {
				// Dynamic matching failed.
				// Skip this interceptor and invoke the next in the chain.
				return proceed();
			}
		}
		else {
			// It's an interceptor, so we just invoke it: The pointcut will have
			// been evaluated statically before this object was constructed.
			return ((MethodInterceptor) interceptorOrInterceptionAdvice).invoke(this);
		}
	}
}

```

