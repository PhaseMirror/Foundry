import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const { name, email, message } = await request.json()

    // Validate input
    if (!name || !email || !message) {
      return NextResponse.json(
        { error: 'Name, email, and message are required' },
        { status: 400 }
      )
    }

    if (!email.includes('@')) {
      return NextResponse.json(
        { error: 'Valid email is required' },
        { status: 400 }
      )
    }

    // TODO: Integrate with your email service or CRM
    // Example services: SendGrid, AWS SES, Resend, etc.
    // const apiKey = process.env.EMAIL_SERVICE_API_KEY
    // const recipientEmail = process.env.CONTACT_EMAIL

    // For now, just log the contact request
    console.log('New contact submission:', { name, email, message })

    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 500))

    return NextResponse.json(
      { message: 'Message sent successfully' },
      { status: 200 }
    )
  } catch (error) {
    console.error('Contact error:', error)
    return NextResponse.json(
      { error: 'Failed to send message' },
      { status: 500 }
    )
  }
}
