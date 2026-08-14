import { NextResponse } from 'next/server'
import { LoopsClient } from 'loops'

export async function POST(request: Request) {
  try {
    const { email } = await request.json()

    // Validate email
    if (!email || !email.includes('@')) {
      return NextResponse.json(
        { error: 'Valid email is required' },
        { status: 400 }
      )
    }

    // Validate API key is configured
    const apiKey = process.env.LOOPS_API_KEY
    if (!apiKey) {
      console.error('LOOPS_API_KEY not configured')
      return NextResponse.json(
        { error: 'Newsletter service not configured' },
        { status: 500 }
      )
    }

    // Initialize Loops client
    const loops = new LoopsClient(apiKey)

    // Subscribe user to Loops
    const response = await loops.createContact(email)

    if (!response.success) {
      console.error('Loops API error:', response)
      return NextResponse.json(
        { error: 'Failed to subscribe' },
        { status: 400 }
      )
    }

    console.log(`New subscription: ${email}`)

    return NextResponse.json(
      { message: 'Successfully subscribed' },
      { status: 200 }
    )
  } catch (error) {
    console.error('Subscription error:', error)
    return NextResponse.json(
      { error: 'Failed to subscribe' },
      { status: 500 }
    )
  }
}
